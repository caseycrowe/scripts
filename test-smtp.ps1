# PowerShell script to test SMTP send to email. Since telnet is no longer installed
# by default on Windows servers, this can serve as a substitute since it will
# echo out any error messages to the terminal. Just fill in variables below to suit


$SmtpServer = 'smtp.server.fqdn' 	# Put SMTP server address here. 
$Port = 25                 		# SMTP server port number – default is 25
$From = 'from@ddress.net'  		# from address - doesn't have to be valid
$To = 'test@recipient.net'    		# email address to send test to 
$Subject = 'SMTP Powershell test'	# email subject
$Body = 'Some test text here'		# email body
 
Send-MailMessage -SmtpServer $SmtpServer -Port $Port -From $From -To $To -Subject $Subject -Body $Body 
