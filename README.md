# Linux7
# ДЗ по Systemd

Выполнено ДЗ по Systemd.

Для развёртывания стенда используется дефолтовоый образ CentOS:

запуск: vagrant up
скрипты для запуска находятся в папке scripts
Дополнительные файлы в папке files

Сделано

### Часть 1. Написать сервис, который будет раз в 30 секунд мониторить лог на предмет наличия ключевого слова. Файл и слово должны задаваться в /etc/sysconfig

Для начала создаём файл с конфигурацией для сервиса в директории /etc/sysconfig - из неё сервис будет брать необходимые переменные.

    [ingorbunovi@centos ~]$ cat /etc/sysconfig/watchlog
    #Configuration file for my watchdog service
    #Place it to /etc/sysconfig
    #File and word in that file that we will be monitored
    WORD="ALERT"
    LOG=/var/log/watchlog.log

Затем создаем /var/log/watchlog.log и пишем туда любые строки и ключевое слово ‘ALERT’

создаём скрипт

    [ingorbunovi@centos ~]$ cat /opt/watchlog.sh 
    #!/bin/bash

    WORD=$1
    LOG=$2
    DATE=`date`

    if grep $WORD $LOG &> /dev/null
    then
       logger "$DATE: I found word, Master!"
       echo "I found it. /n" >> /tmp/log.txt
    else
       exit 0
    fi

Команда logger отправляет лог в системный журнал

Создадим Юнит для сервиса:

    [ingorbunovi@centos ~]$ cat /etc/systemd/system/watchlog.service 
    [Unit]
    Description=My watchlog service
    [Service]
    Type=simple
    EnvironmentFile=/etc/sysconfig/watchlog
    ExecStart=/opt/watchlog.sh $WORD $LOG

Создадим Юнит для таймера:

    [ingorbunovi@centos ~]$ cat /etc/systemd/system/watchlog.timer 
    [Unit]
    Description=Run watchlog script every 30 second
    [Timer]
    #Run 30 sec after boot
    OnBootSec=30
    #Run every 30 second
    OnUnitInactiveSec=30
    Unit=watchlog.service
    [Install]
    WantedBy=multi-user.target
  
Затем достаточно только стартануть timer:

    [root@nginx ~#] systemctl start watchlog.timer
  
 И убедиться в результате:
 
    [root@nginx ~#] tail -f /var/log/messages
    Feb 26 16:48:57 terraform-instance systemd: Starting My watchlog service...
    Feb 26 16:48:57 terraform-instance root: Tue Feb 26 16:48:57 +05 2019: I found word,
    master!
    Feb 26 16:48:57 terraform-instance systemd: Started My watchlog service.
    Feb 26 16:49:27 terraform-instance systemd: Starting My watchlog service...
    Feb 26 16:49:27 terraform-instance root: Tue Feb 26 16:49:27 +05 2019: I found word,
    master!
    Feb 26 16:49:27 terraform-instance systemd: Started My watchlog service.
    
### Из epel установитþ spawn-fcgi и переписать init-скрипт на unit-файл. Имя сервиса должно также называться.

Устанавливаем spawn-fcgi и необходимые для него пакеты:

    yum install epel-release -y && yum install spawn-fcgi php php-cli mod_fcgid httpd -y    

Но перед этим необходимо раскомментировать строки с переменными в /etc/sysconfig/spawn-fcgi

    root@centos ingorbunovi]# cat /etc/sysconfig/spawn-fcgi 
    #You must set some working options before the "spawn-fcgi" service will work.
    #If SOCKET points to a file, then this file is cleaned up by the init script.
    #
    #See spawn-fcgi(1) for all possible options.
    #
    #Example :
    SOCKET=/var/run/php-fcgi.sock
    OPTIONS="-u apache -g apache -s $SOCKET -S -M 0600 -C 32 -F 1 -P /var/run/spawn-fcgi.pid -- /usr/bin/php-cgi"

Unit-file:

    cat /etc/systemd/system/spawn-fcgi.service
    [root@centos ingorbunovi]# cat /etc/systemd/system/spawn-fcgi.service
    [Unit]
    Description=Spawn-fcgi startup service by Otus
    After=network.target

    [Service]
    Type=simple
    PIDFile=/var/run/spawn-fcgi.pid
    EnvironmentFile=/etc/sysconfig/spawn-fcgi
    ExecStart=/usr/bin/spawn-fcgi -n $OPTIONS
    KillMode=process

    [Install]
    WantedBy=multi-user.target
  
systemctl start spawn-fcgi
systemctl status spawn-fcgi



### Дополнить Юнит-файл apache httpd возможностью запустить несколько инстансов сервера с разными конфигами

Для запуска нескольких экземпляров сервиса будем использовать шаблон в конфигурации файла окружения:

    #!/usr/bin/env bash

    echo "--------------------------------------------------------"
    echo "start 03_httpd_twice.sh"
    echo "--------------------------------------------------------"

    echo "------add template in httpd.service------"
    cp /usr/lib/systemd/system/httpd.service /usr/lib/systemd/system/httpd@.service
    sed -i 's/sysconfig\/httpd/sysconfig\/httpd-%I/g' /usr/lib/systemd/system/httpd@.service

    echo "------create and edit two files with environments------"
    cp /etc/sysconfig/httpd /etc/sysconfig/httpd-first && cp /etc/sysconfig/httpd /etc/sysconfig/httpd-second
    sed -i 's/#OPTIONS=/OPTIONS=-f conf\/httpd-first.conf/g' /etc/sysconfig/httpd-first && sed -i 's/#OPTIONS=/OPTIONS=-f conf\/httpd-second.conf/g' /etc/sysconfig/httpd-second

    echo "------create and edit two conf-files httpd------"
    cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd-first.conf && cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd-second.conf
    sed -i 's/Listen 80/Listen 8080/g' /etc/httpd/conf/httpd-second.conf && echo "PidFile /var/run/httpd-second.pid" >> /etc/httpd/conf/httpd-second.conf

    echo "------rebuilding dependency tree services and start new services------"
    systemctl daemon-reload
    systemctl enable --now httpd@first
    systemctl enable --now httpd@second

    #echo "------check that both web servers are running------"
    #ss -lptun | grep 80

    echo "------------------------------------------------------"
    echo "03_httpd_twice.sh finished"
    echo "------------------------------------------------------"
