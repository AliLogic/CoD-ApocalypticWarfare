/*
	My Message Include - Logic_
	-----------------------------------------
	Whenever you add this to your script,
	make sure to define the order, by defining
	#define ORDER [ASCEND/ DESCEND] before you
	include this. Else, you'll get an error.
*/

#define ASCEND (0)
#define DESCEND (1)
#define MAX_MSG (7)
#define MAX_HOLD (128)

#if !defined ORDER
	#error "You must include #define ORDER [ASCEND/ DESCEND]"
#endif
#if ORDER != ASCEND && ORDER != DESCEND
	#error "Invalid #defined ORDER [ASCEND/ DESCEND]"
#endif

new Text: Box, Text: Msg[MAX_MSG], Hold[MAX_MSG][MAX_HOLD];

stock LoadBox()
{
	Box = TextDrawCreate(383.000000, 436.000000, "_");
	TextDrawBackgroundColor(Box, 255);
	TextDrawFont(Box, 1);
	TextDrawLetterSize(Box, -0.000001, -8.899994);
	TextDrawColor(Box, -1);
	TextDrawSetOutline(Box, 0);
	TextDrawSetProportional(Box, 1);
	TextDrawSetShadow(Box, 1);
	TextDrawUseBox(Box, 1);
	TextDrawBoxColor(Box, 100);
	TextDrawTextSize(Box, 638.000000, 0.000000);
	TextDrawSetSelectable(Box, 0);

	for(new i; i < MAX_MSG; i++)
	{
		Msg[i] = TextDrawCreate(384.000000, 359.000000 + (10 * i), "_");
		TextDrawBackgroundColor(Msg[i], 255);
		TextDrawFont(Msg[i], 1);
		TextDrawLetterSize(Msg[i], 0.189998, 1.000000);
		TextDrawColor(Msg[i], -1);
		TextDrawSetOutline(Msg[i], 0);
		TextDrawSetProportional(Msg[i], 1);
		TextDrawSetShadow(Msg[i], 1);
		TextDrawSetSelectable(Msg[i], 0);
	}
	return 1;
}

stock UnloadBox()
{
	TextDrawDestroy(Box);
	for(new i; i < MAX_MSG; i++)
	{
		TextDrawDestroy(Msg[i]);
	}
	return 1;
}

stock SendBoxMessage(msgs[])
{
	#if ORDER == ASCEND
	for(new i = (MAX_MSG - 1); i > -1; i--)
	{
		if(i != 0)
		{
			format(Hold[i], 128, Hold[i - 1]);
		}
		else
		{
			format(Hold[i], 128, msgs);
		}
	}
	for(new i; i < MAX_MSG; i++)
	{
		TextDrawSetString(Msg[i], Hold[i]);
	}
	#else
	for(new i; i < (MAX_MSG); i++)
	{
		if(i == (MAX_MSG - 1))
		{
			format(Hold[(MAX_MSG - 1)], 128, msgs);
		}
		else
		{
			format(Hold[i], 128, Hold[i + 1]);
		}
	}
	for(new i; i < MAX_MSG; i++)
	{
		TextDrawSetString(Msg[i], Hold[i]);
	}
	#endif
	return 1;
}

stock ShowPlayerBox(playerid)
{
	TextDrawShowForPlayer(playerid, Box);
	for(new i; i < MAX_MSG; i++)
	{
		TextDrawShowForPlayer(playerid, Msg[i]);
	}
	return 1;
}

stock HidePlayerBox(playerid)
{
	TextDrawHideForPlayer(playerid, Box);
	for(new i; i < MAX_MSG; i++)
	{
		TextDrawHideForPlayer(playerid, Msg[i]);
	}
	return 1;
}

stock ClearBoxMessage()
{
	for(new i; i < MAX_MSG; i++)
	{
		TextDrawSetString(Msg[i], "_");
		format(Hold[i], 128, "_");
	}
	return 1;
}

/*stock EditBoxMessage(MsgID, msg[])
{
	if(MsgID <= -1 || MsgID >= MAX_MSG) return printf("ERROR: Box message ID %d is invalid, message: %s", MsgID, msg);
	format(Hold[MsgID], 128, msg);
	TextDrawSetString(Msg[MsgID], Hold[MsgID]);
	return 1;
}*/
