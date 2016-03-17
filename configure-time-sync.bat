@echo off

echo Stopping the Windows Time Service

net stop w32time

echo Configuring Windows Time Service

w32tm /config /syncfromflags:manual /manualpeerlist:"time.nist.gov"

w32tm /config /reliable:yes

echo Starting Windows Time Service

net start w32time