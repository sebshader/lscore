/* hack to enable load file in pdlua in order to read chunks */
/* S. Shader */

/* various C stuff, mainly for reading files */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h> // for open
#include <sys/stat.h> // for open

#ifdef _MSC_VER
#include <io.h>
#include <fcntl.h> // for open
#define read _read
#define close _close
#define ssize_t int
#define snprintf _snprintf
#else
#include <sys/fcntl.h> // for open
#include <unistd.h>
#endif
/* we use Lua */
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

/* we use Pd */
#include "m_pd.h"
#include "m_imp.h" // for struct _class

/** Pd object data. */
typedef struct pdlua 
{
    t_object                pd; /**< We are a Pd object. */
    int                     inlets; /**< Number of inlets. */
    struct pdlua_proxyinlet *in; /**< The inlets themselves. */
    int                     outlets; /**< Number of outlets. */
    t_outlet                **out; /**< The outlets themselves. */
    t_canvas                *canvas; /**< The canvas that the object was created on. */
} t_pdlua;

/** Proxy inlet object data. */
typedef struct pdlua_proxyinlet
{
    t_pd            pd; /**< Minimal Pd object. */
    struct pdlua    *owner; /**< The owning object to forward inlet messages to. */
    unsigned int    id; /**< The number of this inlet. */
} t_pdlua_proxyinlet;

typedef struct pdlua_readerdata
{
    int         fd; /**< File descriptor to read from. */
    char        buffer[MAXPDSTRING]; /**< Buffer to read into. */
} t_pdlua_readerdata;

static void pdlua_setrequirepath
( /* FIXME: documentation (is this of any use at all?) */
    lua_State   *L,
    const char  *path
)
{
#ifdef PDLUA_DEBUG
    post("pdlua_setrequirepath: stack top %d", lua_gettop(L));
#endif // PDLUA_DEBUG
    lua_getglobal(L, "pd");
    lua_pushstring(L, "_setrequirepath");
    lua_gettable(L, -2);
    lua_pushstring(L, path);
    if (lua_pcall(L, 1, 0, 0) != 0)
    {
        error("lua: internal error in `pd._setrequirepath': %s", lua_tostring(L, -1));
        lua_pop(L, 1);
    }
    lua_pop(L, 1);
#ifdef PDLUA_DEBUG
    post("pdlua_setrequirepath: end. stack top %d", lua_gettop(L));
#endif // PDLUA_DEBUG
}

static void pdlua_clearrequirepath
( /* FIXME: documentation (is this of any use at all?) */
    lua_State *L
)
{
#ifdef PDLUA_DEBUG
    post("pdlua_clearrequirepath: stack top %d", lua_gettop(L));
#endif // PDLUA_DEBUG
    lua_getglobal(L, "pd");
    lua_pushstring(L, "_clearrequirepath");
    lua_gettable(L, -2);
    if (lua_pcall(L, 0, 0, 0) != 0)
    {
        error("lua: internal error in `pd._clearrequirepath': %s", lua_tostring(L, -1));
        lua_pop(L, 1);
    }
    lua_pop(L, 1);
#ifdef PDLUA_DEBUG
    post("pdlua_clearrequirepath: end. stack top %d", lua_gettop(L));
#endif // PDLUA_DEBUG
}


static const char *pdlua_reader
(
    lua_State *L, /**< Lua interpreter state. */
    void *rr, /**< Lua file reader state. */
    size_t *size /**< How much data we have read. */
)
{
    t_pdlua_readerdata  *r = rr;
    ssize_t             s;
#ifdef PDLUA_DEBUG
    post("pdlua_reader: fd is %d", r->fd);
#endif // PDLUA_DEBUG
    s = read(r->fd, r->buffer, MAXPDSTRING-2);
#ifdef PDLUA_DEBUG
    post("pdlua_reader: s is %ld", s);////////
#endif // PDLUA_DEBUG
    if (s <= 0)
    {
        *size = 0;
        return NULL;
    }
    else
    {
        *size = s;
        return r->buffer;
    }
}

/*  
function pd.Class:getcpath()
*/

/** return the path of the class (mrpeach 20111025), adapted by S. Shader*/

static int pdlua_getcpath(lua_State *L)
/**< Lua interpreter state.
  * \par Inputs:
  * \li \c 1 class.
  * \par Outputs:
  * \li \c 1 Filename string.
  * */
{
    t_class     *class;

#ifdef PDLUA_DEBUG
    post("pdlua_getcpath stack top is %d", lua_gettop(L));
#endif // PDLUA_DEBUG
    lua_pushstring(L, "_class");
    lua_gettable(L, -2);
	class = (t_class *)lua_touserdata(L, -1);
	lua_pop(L, 1);
    lua_pushstring(L, class->c_externdir->s_name);
#ifdef PDLUA_DEBUG
    post("pdlua_getcpath end. stack top is %d", lua_gettop(L));
#endif // PDLUA_DEBUG
    
    return 1;
}

/** get canvas path*/
static int pdlua_getopath(lua_State *L)
/**< Lua interpreter state.
  * \par Inputs:
  * \li \c 1 self.
  * \par Outputs:
  * \li \c 1 filename.
  * */
{
	t_symbol		*symbol;
    t_pdlua             *o;

#ifdef PDLUA_DEBUG
    post("pdlua_loadfile: stack top %d", lua_gettop(L));
#endif // PDLUA_DEBUG
    lua_pushstring(L, "_object");
    lua_gettable(L, -2);
    if (lua_islightuserdata(L, -1))
    {
        o = lua_touserdata(L, -1);
        lua_pop(L, 1);
        if (o)
        {
        	symbol = canvas_getdir(o->canvas);
        	lua_pushstring(L, symbol->s_name);
        }
        else error("lua: error in object:getopath() - object is null");
    }
    else error("lua: error in object:getopath() - object is wrong type");
#ifdef PDLUA_DEBUG
    post("pdlua_loadfile end. stack top is %d", lua_gettop(L));
#endif // PDLUA_DEBUG
    
    return 1;
}

/*  
function pd.Class:loadfile(file)
perhaps redundant with the addition of getopath
*/

/** Run a Lua script using Pd's path.
copied from pdlua_dofile */
static int pdlua_loadfile(lua_State *L)
/**< Lua interpreter state.
  * \par Inputs:
  * \li \c 1 self.
  * \li \c 2 Filename string.
  * \par Outputs:
  * \li \c 1 loaded chunk.
  * */
{
    char                buf[MAXPDSTRING];
    char                *ptr;
    t_pdlua_readerdata  reader;
    int                 fd;
    const char          *filename;
    t_pdlua             *o;

#ifdef PDLUA_DEBUG
    post("pdlua_loadfile: stack top %d", lua_gettop(L));
#endif // PDLUA_DEBUG
    lua_pushstring(L, "_object");
    lua_gettable(L, -3);
    if (lua_islightuserdata(L, -1))
    {
        o = lua_touserdata(L, -1);
        lua_pop(L, 1);
        if (o)
        {
            filename = luaL_optstring(L, 2, NULL);
            fd = canvas_open(o->canvas, filename, "", buf, &ptr, MAXPDSTRING, 1);
            if (fd >= 0)
            {
#ifdef PDLUA_DEBUG
                post("pdlua_loadfile path is %s", buf);
#endif // PDLUA_DEBUG
                //pdlua_setpathname(o, buf);/* change the scriptname to include its path */
                pdlua_setrequirepath(L, buf);
                reader.fd = fd;
#if LUA_VERSION_NUM	< 502
                if (lua_load(L, pdlua_reader, &reader, filename))
#else // 5.2 style
                if (lua_load(L, pdlua_reader, &reader, filename, NULL))
#endif // LUA_VERSION_NUM	< 502
                {
                    close(fd);
                    pdlua_clearrequirepath(L);
                    lua_error(L);
                }
                else
                {
					/* succeeded */
					close(fd);
					pdlua_clearrequirepath(L);
                }
            }
            else pd_error(o, "lua: error loading `%s': canvas_open() failed", filename);
        }
        else error("lua: error in object:loadfile() - object is null");
    }
    else error("lua: error in object:loadfile() - object is wrong type");
#ifdef PDLUA_DEBUG
    post("pdlua_loadfile end. stack top is %d", lua_gettop(L));
#endif // PDLUA_DEBUG
    
    return 1;
}


//called when pdlload starts
int luaopen_pdlload(lua_State *L) {
	lua_getglobal(L, "pd");
	lua_pushstring(L, "Class");
	lua_gettable(L, -2);
	lua_pushstring(L, "loadfile");
	lua_pushcfunction(L, pdlua_loadfile);
	lua_settable(L, -3);
	lua_pushstring(L, "getcpath");
	lua_pushcfunction(L, pdlua_getcpath);
	lua_settable(L, -3);
	lua_pushstring(L, "getopath");
	lua_pushcfunction(L, pdlua_getopath);
	lua_settable(L, -3);
	return 0;
}

