#!/bin/bash

##########################################################################################################
#~ bug in icst.c in arch/arm/common
#~ Repo nur cm14.1 auschecken
#~ Umbau, wenn gohan alle Patches einspielen, Frage ob alle Proz oder nur 4, CleanBuild hei�t l�schen des $Out Verzeichnisses
##########################################################################################################

    #~ <string name="data_usage_app_restrict_all_vpn_title">Alle VPN Datenzugriffe deaktivieren</string>
    #~ <string name="data_usage_app_restrict_all_vpn_summary">Jegliche Datenzugriffe �ber VPN verhindern</string>        
    #~ <string name="data_usage_app_restrict_vpn_category_title">VPN-Datenzugriff</string>
    #~ in /media/lta-user/Backup/android/lineage14.1/packages/apps/Settings/res/values-de/cm_strings.xml

#~ Audio einstellungen liegn im Pfad
    #~ android/lineage14.1/frameworks/av/services/audiopolicy/config/

#~ <Compiler festnageln>
        #~ https://askubuntu.com/questions/873278/linux-kernel-version-and-gcc-version-match
        #~ https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/tree/?id=refs/tags/v3.10.108
        #~ https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/tree/README?id=refs/tags/v3.10.108
#~ <Compiler festnageln>

#~ <HID-Voice und VoLTE unterschiede Leeco/14/16 nach gohan>
        #~ /media/lta-user/Backup/android/DeviceSpecific/android_device_leeco_s2/overlay/frameworks/base/core/res/res/values/config.xml
	#~ /media/lta-user/Backup/android/DeviceSpecific/android_device_leeco_s2/audio/audio_platform_info.xml
	#~ /media/lta-user/Backup/android/DeviceSpecific/android_device_leeco_s2/audio/mixer_paths_qrd_skun_cajon.xml
	#~ /media/lta-user/Backup/android/DeviceSpecific/android_device_leeco_s2/system.prop
	#~ gohan
	#~ /media/lta-user/Backup/android/DeviceSpecific/android_device_bq_gohan/audio/mixer_paths_qrd_skun.xml
#~ <HID-Voice und VoLTE unterschiede Leeco/14/16 nach gohan>

	#~ fastcharge aus cyclon kernel


#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wunused-parameter"

#pragma GCC diagnostic pop


##########################################################################################################
# Definitionen
##########################################################################################################

#d=$(date +%Y-%m-%d-%H-%M)
buildDate=$(date +%Y%m%d)

#RootPfad=/media/lta-user/Backup
RootPfad=$PWD
CertPfad=/media/lta-user/Backup
limitCpu=false
clearBuild=false
target=gohan
kernel=msm8976

##########################################################################################################

##########################################################################################################
##########################################################################################################
##########################################################################################################
##########################################################################################################
# Functionen
##########################################################################################################

##########################################################################################################
# FunktionsName getTarget
# details               Auswahl des zu bauenden Bq Targets
##########################################################################################################
function getTarget {
    xmessage -buttons "gohan":0,"tenshi":1 -default "gohan" -nearmouse "Target ausw�hlen"
    if [ $? = 1 ] 
    then
        target=tenshi
        kernel=msm8937
        privApp=false
        paramPatch=false
    fi
}

##########################################################################################################
# FunktionsName limitUsedCpu
# details               weitere Apps
##########################################################################################################
function limitUsedCpu {
    xmessage -buttons "Nein":0,"Ja":1 -default "Nein" -nearmouse "Anzahl der Prozessoren begrenzen?"
    if [ $? = 1 ] 
    then
        limitCpu=true
    fi
}

##########################################################################################################
# FunktionsName cleanBuild
# details               weitere Apps
##########################################################################################################
function cleanBuild {
    xmessage -buttons "Nein":0,"Ja":1 -default "Nein" -nearmouse "Den Build Ordner vorher l�schen?"
    if [ $? = 1 ] 
    then
        clearBuild=true
    fi
}

##########################################################################################################
# FunktionsName showFeature
# details               zeigtdie Zusammenfassung
##########################################################################################################
function showFeature {
    
    msgBuild="nicht gel�scht"
    if [ $clearBuild = true ]
    then
        msgBuild="gel�scht"
    fi
    
    msgCpu="unbegrenzt"
    if [ $limitCpu = true ]
    then
        msgCpu="begrenzt"
    fi

    #~ xmessage -buttons "Passt":0,"Abbruch":1 -default "Abbruch" -nearmouse "Target: $target$msgPrivApp$msgParamPatch. Prozessorzahl $msgCpu, Buildverzeichnis $msgBuild"
    xmessage -buttons "Passt":0,"Abbruch":1 -default "Abbruch" -nearmouse "Target: $target. Prozessorzahl $msgCpu, Buildverzeichnis $msgBuild"
    if [ $? = 1 ] 
    then
        exit
    fi
}

##########################################################################################################
# FunktionsName Exit
# details               Beenden
##########################################################################################################
function quit {
    echo $1 & "  schlug fehl"
    exit
}

##########################################################################################################
# FunktionsName  securityPatchDate
# details               der PatchStand auf der Platte
##########################################################################################################
function securityPatchDate {
    echo +++++++++++++++++++++++++++++++++++ Patch Datum +++++++++++++++++++++++++++++++++++++++++++++++++
    echo
    #grep "PLATFORM_SECURITY_PATCH := " ./build/core/version_defaults.mk 
    LOCAL=$(grep -Eoi "PLATFORM_SECURITY_PATCH := .*" ./build/core/version_defaults.mk | sed  s@'PLATFORM_SECURITY_PATCH := '@''@)
    echo Security Patch Level lokal vom  : $LOCAL
    echo
}

##########################################################################################################
# FunktionsName  newPatchesAvailable
# details               gibts einen neueren PatchStand
##########################################################################################################
function newPatchesAvailable {
    echo +++++++++++++++++++++++++++++++++++ Security Patches ++++++++++++++++++++++++++++++++++++++++++++++++
    echo
    LOCAL=$(grep -Eoi "PLATFORM_SECURITY_PATCH := .*" ./build/core/version_defaults.mk | sed  s@'PLATFORM_SECURITY_PATCH := '@''@)
    REMOTE=$(curl -sS https://github.com/LineageOS/android_build/blob/cm-14.1/core/version_defaults.mk | grep -Eoi 'PLATFORM_SECURITY_PATCH</span> := [0-9]{4}-[0-9]{2}-[0-9]{2}' | sed  s@'PLATFORM_SECURITY_PATCH</span> := '@''@)

    echo Security Patch Level lokal vom  : $LOCAL
    echo Security Patch Level remote vom: $REMOTE    
    
    # wenn l�nge = 0 keine verbindung zum server
    if [ ${#REMOTE} = 0 ]
    then
        echo "Keine Verbindung zum Server"
        exit
    fi    
    if [ ${#LOCAL} = 0 ] 
    then
        echo "Kein Repo gefunden, starte sync"
        return
    fi    

    if [ $LOCAL = $REMOTE ]; then
        xmessage -buttons "Trotzdem bauen":0,"Beenden":1 -default "Beenden" -nearmouse "Keine neuen Patches vorhanden"
        if [ $? = 1 ] 
        then
            echo "Beenden"
            exit
        fi
    else
        xmessage -buttons "Build!":0,"Beenden":1 -default "Beenden" -nearmouse "Neue Patches vorhanden"
        if [ $? = 1 ] 
        then
            echo "Beenden"
            exit
        fi
    fi
}

##########################################################################################################
# FunktionsName prepCache
# details               Cache l�schen und vorbereiten
##########################################################################################################
function prepCache {
    echo +++++++++++++++++++++++++++++++++++ Cleanup Cache  ++++++++++++++++++++++++++++++++++++++++++++++
    echo
    ccache -C 
    
    if [ $clearBuild = true ] && [ -d "$RootPfad/android/lineage14.1/out" ]
    then
        echo "out geloescht"
        rm -r $RootPfad/android/lineage14.1/out
    fi
    
    echo
    echo +++++++++++++++++++++++++++++++++++ Cleanup Cache  beendet ++++++++++++++++++++++++++++++++++++++
    # Cache Einstellungen
    export USE_CCACHE=1
    #ccache -M 75G
    export CCACHE_COMPRESS=1
    export ANDROID_JACK_VM_ARGS="-Dfile.encoding=UTF-8 -XX:+TieredCompilation -Xmx4G"
    echo
}

##########################################################################################################
# FunktionsName restorePatches
# details               die ge�nderten Scripte wiederherstellen
##########################################################################################################
function restorePatches {
    echo
    echo "Parameter wieder zuruecksetzen"
    
    # Die Buildumgebung wieder zur�ck
    replaceWith="mk_timer schedtool -B -n 10 -e ionice -n 7 make -C \$T -j\$(grep \"\^processor\" /proc/cpuinfo | wc -l) \"\$@\""
    searchString="mk_timer schedtool -B -n 10 -e ionice -n 7 make -C \$T -j4 \"\$@\""
    #searchString="mk_timer schedtool -B -n 10 -e ionice -n 7 make -C \$T -j1 \"\$@\""
    sed -i -e "s:${searchString}:${replaceWith}:g" $RootPfad/android/lineage14.1/vendor/cm/build/envsetup.sh

    echo Anzahl Prozessoren
    grep -Eoi "mk_timer schedtool -B -n 10 -e ionice .*" $RootPfad/android/lineage14.1/vendor/cm/build/envsetup.sh 
    
    echo Ant+        
    grep -Eoi '<string name="def_airplane_mode_radios" translatable.*'  ./frameworks/base/packages/SettingsProvider/res/values/defaults.xml       
    searchString="<string name=\"def_airplane_mode_radios\" translatable=\"false\">cell,bluetooth,wifi,nfc,wimax,ant</string>"
    replaceWith="<string name=\"def_airplane_mode_radios\" translatable=\"false\">cell,bluetooth,wifi,nfc,wimax</string>"
    sed -i -e "s:${searchString}:${replaceWith}:g" ./frameworks/base/packages/SettingsProvider/res/values/defaults.xml
    grep -Eoi '<string name="def_airplane_mode_radios" translatable.*'  ./frameworks/base/packages/SettingsProvider/res/values/defaults.xml
    
    grep -Eoi '<string name="airplane_mode_toggleable_radios" translatable.*'  ./frameworks/base/packages/SettingsProvider/res/values/defaults.xml       
    searchString="<string name=\"airplane_mode_toggleable_radios\" translatable=\"false\">bluetooth,wifi,nfc,ant</string>"
    replaceWith="<string name=\"airplane_mode_toggleable_radios\" translatable=\"false\">bluetooth,wifi,nfc</string>"
    sed -i -e "s:${searchString}:${replaceWith}:g" ./frameworks/base/packages/SettingsProvider/res/values/defaults.xml
    grep -Eoi '<string name="airplane_mode_toggleable_radios" translatable.*'  ./frameworks/base/packages/SettingsProvider/res/values/defaults.xml

}

##########################################################################################################
# Functionen
##########################################################################################################
##########################################################################################################
##########################################################################################################
##########################################################################################################


##########################################################################################################
# Wechsel ins Buildverzeichnis
##########################################################################################################
echo +++++++++++++++++++++++++++++++++++ In das Buildverzeichnis +++++++++++++++++++++++++++++++++++++++++
echo
cd $RootPfad/android/lineage14.1
pwd
echo
# gibts neue security patches
newPatchesAvailable
# f�r welches Target bauen wir
getTarget
# Prozessoren begrenzen
limitUsedCpu
# BuildOrdner l�schen
cleanBuild
#Zusammenfassung
showFeature

##########################################################################################################
# Repo init und sync
##########################################################################################################
echo +++++++++++++++++++++++++++++++++++ Init Repo  ++++++++++++++++++++++++++++++++++++++++++++++++++++++
repo init -u https://github.com/LineageOS/android.git -b cm-14.1
echo
if [ $? -ne 0 ] 
then
    quit "repo Init"
fi

echo +++++++++++++++++++++++++++++++++++ Sync Repo  ++++++++++++++++++++++++++++++++++++++++++++++++++++++
echo
echo sync
repo sync
if [ $? -ne 0 ] 
then
    quit "repo sync"
fi
echo

##########################################################################################################
# Android Security Patch Level auslesen
##########################################################################################################
securityPatchDate

##########################################################################################################
# Target bauen
##########################################################################################################
while : ; do

    echo +++++++++++++++++++++++++++++++++++ Den Code fuer $target   +++++++++++++++++++++++++++++++++++++++++
    echo
    source build/envsetup.sh
    breakfast $target
    echo
    if [ $? -ne 0 ] 
    then
        quit "breakfast $target"
    fi

    ##########################################################################################################
    # Cache
    ##########################################################################################################
    prepCache

    ##########################################################################################################
    # Build auf x Cpu Cores begrenzen
    ########################################################################################################## 
    if [ $limitCpu = true ]
    then
        searchString="mk_timer schedtool -B -n 10 -e ionice -n 7 make -C \$T -j\$(grep \"\^processor\" /proc/cpuinfo | wc -l) \"\$@\""
        replaceWith="mk_timer schedtool -B -n 10 -e ionice -n 7 make -C \$T -j4 \"\$@\""
        #replaceWith="mk_timer schedtool -B -n 10 -e ionice -n 7 make -C \$T -j1 \"\$@\""
        sed -i -e "s:${searchString}:${replaceWith}:g" $RootPfad/android/lineage14.1/vendor/cm/build/envsetup.sh
    fi

    ##########################################################################################################
    # meine git Repos synchen
    # test wie es geht,
    # l�schen und clonen, da repo synch es vorher �berschrieben hat
    # oder
    # nur synchen (git pull)
    
    
    ##########################################################################################################
    # device bg $target synchen
    #git clone https://github.com/moosburger/android_device_bq_$target.git device/bq/$target

    # external Ant-Wireless synchen
    git clone https://github.com/moosburger/android_external_ant-wireless.git external/ant-wireless

    # vendor bg $target synchen
    git clone https://github.com/moosburger/android_vendor_bq_$target.git vendor/bq/$target

    ##########################################################################################################
    # Files austauschen, patchen, hinzuf�gen
    ##########################################################################################################
    echo +++++++++++++++++++++++++++++++++++ Dateien austauschen, patchen, hinzufuegen   +++++++++++++++++++++++++++++++
    echo
    
    if [ $target = gohan  ]
    then
        echo Ant+        
        grep -Eoi '<string name="def_airplane_mode_radios" translatable.*'  ./frameworks/base/packages/SettingsProvider/res/values/defaults.xml       
        searchString="<string name=\"def_airplane_mode_radios\" translatable=\"false\">cell,bluetooth,wifi,nfc,wimax</string>"
        replaceWith="<string name=\"def_airplane_mode_radios\" translatable=\"false\">cell,bluetooth,wifi,nfc,wimax,ant</string>"
        sed -i -e "s:${searchString}:${replaceWith}:g" ./frameworks/base/packages/SettingsProvider/res/values/defaults.xml
        grep -Eoi '<string name="def_airplane_mode_radios" translatable.*'  ./frameworks/base/packages/SettingsProvider/res/values/defaults.xml
        
        grep -Eoi '<string name="airplane_mode_toggleable_radios" translatable.*'  ./frameworks/base/packages/SettingsProvider/res/values/defaults.xml       
        searchString="<string name=\"airplane_mode_toggleable_radios\" translatable=\"false\">bluetooth,wifi,nfc</string>"
        replaceWith="<string name=\"airplane_mode_toggleable_radios\" translatable=\"false\">bluetooth,wifi,nfc,ant</string>"
        sed -i -e "s:${searchString}:${replaceWith}:g" ./frameworks/base/packages/SettingsProvider/res/values/defaults.xml
        grep -Eoi '<string name="airplane_mode_toggleable_radios" translatable.*'  ./frameworks/base/packages/SettingsProvider/res/values/defaults.xml
    fi
       
    echo gps.conf im Ordner austauschen
    cp $RootPfad/android/packages/modifizierte/gps.conf $RootPfad/android/lineage14.1/device/bq/$target/gps/etc/gps.conf
    echo    
    
    echo BqCamera  aktualisieren, wenn neu. da in Github eingecheckt brauchts dies nicht mehr
    cp $RootPfad/android/packages/modifizierte/cm_strings.xml $RootPfad/android/lineage14.1/packages/apps/Settings/res/values-de/cm_strings.xml
    echo
    
    echo BqCamera  aktualisieren, wenn neu. da in Github eingecheckt brauchts dies nicht mehr
    cp $RootPfad/android/packages/modifizierte/default_volume_tables.xml $RootPfad/ndroid/lineage14.1/frameworks/av/services/audiopolicy/config/default_volume_tables.xml
    echo
    
       
    #echo BqCamera  aktualisieren, wenn neu. da in Github eingecheckt brauchts dies nicht mehr
    #cp $RootPfad/android/packages/priv-app/BqCamera/BqCamera.apk $RootPfad/android/lineage14.1/vendor/bq/$target/proprietary/priv-app/BqCamera/BqCamera.apk
    #echo
        
    echo +++++++++++++++++++++++++++++++++++ Dateien austauschen, patchen, hinzufuegen  beendet ++++++++++++++++++++++++
    echo

    ##########################################################################################################
    # Build
    ##########################################################################################################
    echo +++++++++++++++++++++++++++++++++++ Starte unsignierten Build  ++++++++++++++++++++++++++++++++++++++
    echo
    croot
    brunch $target
    if [ $? -ne 0 ] 
    then
        echo "brunch $target schlug fehl"
        break
    fi
    echo +++++++++++++++++++++++++++++++++++ Ende unsignierter Build  ++++++++++++++++++++++++++++++++++++++++
    echo
    echo +++++++++++++++++++++++++++++++++++ Starte signierten Build  ++++++++++++++++++++++++++++++++++++++++
    echo
    mka target-files-package otatools
    if [ $? -ne 0 ] 
    then
        echo "otatools $target schlug fehl"
        break
    fi
    echo
    echo +++++++++++++++++++++++++++++++++++ APK +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    echo
    croot
    python ./build/tools/releasetools/sign_target_files_apks -o -d $CertPfad/.android-certs $OUT/obj/PACKAGING/target_files_intermediates/*-target_files-*.zip $RootPfad/$target-files-signed.zip 
    if [ $? -ne 0 ]
    then
        echo "$target APK signieren schlug fehl"
        break
    fi
    echo
    echo +++++++++++++++++++++++++++++++++++ OTA +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    echo
    python ./build/tools/releasetools/ota_from_target_files -k $CertPfad/.android-certs/releasekey --block --backup=true $RootPfad/$target-files-signed.zip $RootPfad/$target-ota-update.zip
    if [ $? -ne 0 ]
    then
        echo "$target OTA signieren schlug fehl"
        break
    fi
    echo
    echo +++++++++++++++++++++++++++++++++++ Ende signierter Build  ++++++++++++++++++++++++++++++++++++++++++
    echo
    
break
done

##########################################################################################################
# Android Security Patch Level auslesen
##########################################################################################################
securityPatchDate

if [ -f $RootPfad/$target-files-signed.zip ]
then
    rm $RootPfad/$target-files-signed.zip
fi

# Kopieren und umbenennen
if [ -f $RootPfad/$target-ota-update.zip ]
then
    echo "verschiebe $RootPfad/$target-ota-update.zip ==> $RootPfad/lineage-14.1-$buildDate-UNOFFICIAL-$target-signed.zip"
    mv $RootPfad/$target-ota-update.zip $RootPfad/lineage-14.1-$buildDate-UNOFFICIAL-$target-signed.zip
fi

if [ -f $OUT/lineage-14.1-*-UNOFFICIAL-$target.zip ]
then
    echo "verschiebe $OUT/lineage-14.1-*-UNOFFICIAL-$target.zip ==> $RootPfad/lineage-14.1-*-UNOFFICIAL-$target.zip"
    mv $OUT/lineage-14.1-*-UNOFFICIAL-$target.zip $RootPfad
    echo "verschiebe $OUT/lineage-14.1-*-UNOFFICIAL-$target.zip.md5sum ==> $RootPfad/lineage-14.1-*-UNOFFICIAL-$target.zip.md5sum"
    mv $OUT/lineage-14.1-*-UNOFFICIAL-$target.zip.md5sum $RootPfad
fi

restorePatches
    
##########################################################################################################