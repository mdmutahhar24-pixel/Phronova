Set shell = CreateObject("WScript.Shell")

serverPath = WScript.Arguments(0)

shell.Run """" & serverPath & """", 0, False
