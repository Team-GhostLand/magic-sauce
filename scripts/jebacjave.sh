#
#http://askubuntu.com/questions/84483/how-to-completely-uninstall-java 
#

java_version=`java -version 2>&1 | head -n 1 | awk -F"\"" '{print $2}'`

#Remove all the Java related packages (Sun, Oracle, OpenJDK, IcedTea plugins, GIJ):
sudo apt-get update
apt-cache search java | awk '{print($1)}' | grep -E -e '^(ia32-)?(sun|oracle)-java' -e '^openjdk-' -e '^icedtea' -e '^(default|gcj)-j(re|dk)' -e '^gcj-(.*)-j(re|dk)' -e 'java-common' | xargs sudo apt-get -y remove
sudo apt-get -y autoremove

#Purge config files:
dpkg -l | grep ^rc | awk '{print($2)}' | xargs sudo apt-get -y purge

#Remove Java config and cache directory:
sudo bash -c 'ls -d /home/*/.java' | xargs sudo rm -rf

#Remove manually installed JVMs:
sudo rm -rf /usr/lib/jvm/*

#Remove Java entries, if there is still any, from the alternatives:
for g in ControlPanel java java_vm javaws jcontrol jexec keytool mozilla-javaplugin.so orbd pack200 policytool rmid rmiregistry servertool tnameserv unpack200 appletviewer apt extcheck HtmlConverter idlj jar jarsigner javac javadoc javah javap jconsole jdb jhat jinfo jmap jps jrunscript jsadebugd jstack jstat jstatd native2ascii rmic schemagen serialver wsgen wsimport xjc xulrunner-1.9-javaplugin.so; do sudo update-alternatives --remove-all $g; done

#Search for possible remaining Java directories:
sudo updatedb
cd /tmp
for i in `sudo locate -b '\pack200'`; do sudo rm -rf $i; done
sudo updatedb
#If the command above produces any output like /path/to/jre1.6.0_34/bin/pack200 remove the directory that is parent of bin, like this: sudo rm -rf /path/to/jre1.6.0_34.

sudo apt-get purge openjdk-\* icedtea-\* icedtea6-\*
sudo update-alternatives --display java
sudo update-alternatives --remove "java" "/usr/lib/jvm/jdk$java_version/bin/java"
sudo update-alternatives --remove "javac" "/usr/lib/jvm/jdk$java_version/bin/javac"
sudo update-alternatives --remove "javaws" "/usr/lib/jvm/jdk$java_version/bin/javaws"

#verify that the symlinks were removed
#java -version
#javac -version
#which javaws

#The next 2 commands must be type excatly perfectly to avoid permanently destroying your system.
#cd /usr/lib/jvm ja tinha sido apagado
#sudo rm -rf jdk$java_version

#Then do
sudo update-alternatives --config java
sudo update-alternatives --config javac
sudo update-alternatives --config javaws

#To uninstall OpenJDK (if installed). First check which OpenJDK packages are installed.
sudo dpkg --list | grep -i jdk

#To remove openjdk:
sudo apt-get purge openjdk*

#Uninstall OpenJDK related packages.
sudo apt-get purge icedtea-* openjdk-*

#Check that all OpenJDK packages have been removed.
sudo dpkg --list | grep -i jdk

sudo update-alternatives --config java
sudo apt-get autoremove openjdk-6-jre
sudo apt-get autoremove openjdk-7-jre
sudo apt-get autoremove openjdk-$java_version-jdk

#
#http://www.hugomaiavieira.com/2012/02/problema-com-o-guardiao-itau-no-linux.html
#

echo "deb http://www.duinsoft.nl/pkg debs all" > /tmp/duinsoft.list
sudo mv /tmp/duinsoft.list /etc/apt/sources.list.d
sudo apt-key adv --keyserver keys.gnupg.net --recv-keys 5CB26B26
sudo apt-get update
sudo apt-get install update-sun-jre