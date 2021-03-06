#include <a_samp>
#include <smartcmd>
#include <sscanf2>
#include "core/enums/privileges.pwn"

#define COLOR_DEFAULT			0xAAAAAAFF
#define COLOR_FAILURE           0xD62B20FF

new objects;
new objectmodel[500];

COMMAND<PRIVILEGE_ADMINISTRATOR>:newtobject(cmdid, playerid, params[])
{
    new oid,obj;
    if (!sscanf(params,"i",oid))
    {
        new string[128];
        new Float:x, Float:y, Float:z;
        GetPlayerPos(playerid, x, y, z);
        obj = CreateObject(oid, x+2, y+2, z+2, 0.0, 0.0, 90.0);
        format(string, sizeof(string), "Created a new temporary object (ID: %d) at %f,%f,%f,0.0,0.0,90.0",obj,oid,x,y,z);
        SendClientMessage(playerid,COLOR_DEFAULT,string);
        objectmodel[obj]=oid;
        objects++;
        EditObject(playerid, oid);
        return 1;
    }
    return SendClientMessage(playerid,COLOR_FAILURE,"Usage: /newtobject [object id]");
}

COMMAND<PRIVILEGE_ADMINISTRATOR>:edittobject(cmdid, playerid, params[])
{
    new oid;
    if (!sscanf(params,"i",oid))
    {
        EditObject(playerid, oid);
        return 1;
    }
    return SendClientMessage(playerid,COLOR_FAILURE,"Usage: /edittobject [object id]");
}

public OnPlayerEditObject(playerid, playerobject, objectid, response, Float:fX, Float:fY, Float:fZ, Float:fRotX, Float:fRotY, Float:fRotZ)
{
    if(response == EDIT_RESPONSE_FINAL)
    {
        SetObjectPos(objectid,fX,fY,fZ);
        SetObjectRot(objectid,fRotX,fRotY,fRotZ);
        return 1;
    }
    return 1;
}