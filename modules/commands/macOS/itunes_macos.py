class command:
    def __init__(self):
        self.name = "itunes"
        self.description = "iTunes Controller"
        self.type = "applescript"

    def run(self,session,cmd_data):
    	if cmd_data['args'] == "next":
        	payload = """
            tell application \"iTunes\"
                with timeout of 2 seconds 
                    next track
                end timeout
            end tell"""
        elif cmd_data['args'] == "prev":
        	payload = """
            tell application \"iTunes\"
                with timeout of 2 seconds 
                    previous track
                end timeout
            end tell"""
        elif cmd_data['args'] == "pause":
        	payload = """
            tell application \"iTunes\"
                with timeout of 2 seconds 
                    pause
                end timeout
            end tell"""
       	elif cmd_data['args'] == "play":
        	payload = """
            tell application \"iTunes\"
                with timeout of 2 seconds 
                    play
                end timeout
            end tell"""
        elif cmd_data['args'] == "airplay":
            payload = """
            tell application "iTunes"
                with timeout of 5 seconds
                    set apDevices to (get every AirPlay device whose available is true)
                    set current AirPlay devices to apDevices
                end timeout
            end tell
            """
        elif cmd_data['args'] == "info":
			payload = """
			tell application "iTunes"
                with timeout of 5 seconds
    		        if player state is paused then
    		        	"Music not playing"
    		        else
    		        	set trackName to name of current track
    		        	set trackAlbum to album of current track
    		        	set trackArtist to artist of current track
    		        	"Track: " & trackName & "\n" & "Album: " & trackAlbum & "\n" & "Artist: " & trackArtist
    		        end
                end timeout
        	end tell"""
        else:
            print "Usage: itunes play|pause|next|prev|info|airplay"
            return
        cmd_data.update({"cmd":"applescript","args":payload})
        result = session.send_command(cmd_data)
        if result:
            print result
