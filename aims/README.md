# AIMS
This project use TypeScript, ExpressJS, Express-Session and SQLite.

# Config
|Variable|Mendated|Usage|
|`PORT`|No|Set the HTTP port the app will listening on. Default is `5000`.
|`LDAP_SERVER`|No|
|`LDAP_DC`|No|
|`AUTHORIZED_USERS`|Usernames separated with a coma (`,`) to limit the people who can access the system. Can be empty to allow everyone.

Note: if the LDAP config is not set, the LDAP authentication will oblivously not be possible.

# Authentication
If the hostname is `localhost`, since we're on the local network, we don't prompt for authentication.