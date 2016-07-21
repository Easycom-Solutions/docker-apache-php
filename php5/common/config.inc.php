<?php

require('./config.secret.inc.php');

$hosts = array('db');
$i = 0;
$i++;

$cfg['Servers'][$i]['host'] = 'db';
$cfg['Servers'][$i]['auth_type'] = 'cookie';
$cfg['Servers'][$i]['connect_type'] = 'tcp';
$cfg['Servers'][$i]['compress'] = false;
$cfg['Servers'][$i]['AllowNoPassword'] = false;

/* Uploads setup */
$cfg['UploadDir'] = '';
$cfg['SaveDir'] = '';