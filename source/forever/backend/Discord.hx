package forever.backend;

#if DISCORD_RPC
import discord_rpc.DiscordRpc;
import lime.app.Application;

typedef DiscordRPCData = {
	var clientID:String;
	var ?icon:String;
	var ?largeImageText:String;
}
#end

/**
	Discord Rich Presence
**/
class Discord {
	#if DISCORD_RPC
	static var rpcData:DiscordRPCData;
	#end

	// set up the rich presence initially
	public static function initializeRPC() {
		#if DISCORD_RPC
		var ini = new SSIni(Paths.data("discordRpc", TXT).trim());

		rpcData = {
			clientID: ini.getSection().clientID,
			icon: ini.getSection().icon,
			largeImageText: ini.getSection().largeImageText.replace("$ENGINE_VERSION", Main.gameVersions["normal"].toString()),
		};

		DiscordRpc.start({
			clientID: rpcData.clientID,
			onReady: onReady,
			onError: onError,
			onDisconnected: onDisconnected,
		});

		// THANK YOU GEDE
		Application.current.window.onClose.add(shutdownRPC);
		#end
	}

	#if DISCORD_RPC
	static function onReady() {
		DiscordRpc.presence({
			details: "",
			state: null,
			largeImageKey: rpcData.icon,
			largeImageText: rpcData.largeImageText
		});
	}

	static function onError(_code:Int, _message:String) {
		print('Error! ${_code} : ${_message}', ERROR);
	}

	static function onDisconnected(_code:Int, _message:String) {
		print('Disconnected! ${_code} : ${_message}', ERROR);
	}
	#end

	public static function changePresence(details:String = '', state:Null<String> = '', ?smallImageKey:String, ?hasStartTimestamp:Bool, ?endTimestamp:Float) {
		#if DISCORD_RPC
		var startTimestamp:Float = (hasStartTimestamp) ? Date.now().getTime() : 0;

		if (endTimestamp > 0)
			endTimestamp = startTimestamp + endTimestamp;

		DiscordRpc.presence({
			details: details,
			state: state,
			largeImageKey: rpcData.icon,
			largeImageText: rpcData.largeImageText,
			smallImageKey: smallImageKey,
			// Obtained times are in milliseconds so they are divided so Discord can use it
			startTimestamp: Std.int(startTimestamp / 1000),
			endTimestamp: Std.int(endTimestamp / 1000)
		});
		#end
	}

	public static function shutdownRPC() {
		#if DISCORD_RPC
		// borrowed from izzy engine -- somewhat, at least
		DiscordRpc.shutdown();
		#end
	}
}
