
# Docker image for Apache + PHP-FPM

## How to use this image

You can set a custom default user (other than the user #33, `www-data`) to give specific access to your mounted volumes with variables `FPM_USERNAME`, `FPM_UID`, `FPM_GROUPNAME` and `FPM_GID`.
All mails are sent to a SMTP server at `mail:25`.
