#How to Enable AAA Radius Authentication on Cisco IOS Switches

##Enable AAA Authentication
`aaa new-model`

**Depending on what IOS version the switch is running the code below will be different, if the new method does not work, try the old method**

**NEW METHOD**

```
radius server <<RADIUS SERVER NAME>>
address ipv4 <<RADIUS SERVER IP>>
key <<RADIUS SERVER CLIENT KEY>>
aaa group server radius <<RADIUS SERVER GROUP NAME>>
server name <<RADIUS SERVER NAME>>
```

**OLD METHOD**

```
radius-server host <<RADIUS SERVER IP>> key <<RADIUS SERVER CLIENT KEY>>
aaa group server radius <<RADIUS SERVER GROUP NAME>>
server <<RADIUS SERVER IP>>
```

**From here on the code is the same**

##Create AAA Control Groups - Checks local first, then RADIUS otherwise will fail if RADIUS is checked first will not fall back nicely to local

```
aaa authentication login VTY_authen local group <<RADIUS  SERVER  GROUP  NAME>>
aaa authorization exec VTY_author local group <<RADIUS  SERVER  GROUP  NAME>>
aaa authorization console
aaa accounting exec default
```
##Enable SSH AAA Auth
```
line vty 0 4
authorization exec VTY_author
login authentication VTY_authen
```

##Enable HTTP(S) AAA Auth
```
ip http authentication aaa login-authentication VTY_authen
ip http authentication aaa exec-authorization VTY_author
```
##Console Authentication
```  
line con 0
authorization exec VTY_author
login authentication VTY_authen
``` 

##Stop Default Authentication - This will stop auth on console unless config applied to console
```
aaa authentication login default none
aaa authorization exec default none
```

##Test Authentication 
```
test aaa group <<RADIUS  SERVER  GROUP  NAME>> <<USER  LOGIN  TO  TEST  OMITTING  DOMAIN> <<USER  PASSWORD>> new-code
```
  
##Enable Default Auth Control Groups if required - Checks local first, then RADIUS otherwise will fail if RADIUS is checked first will not fall back nicely to local
```
aaa authentication login default local group <<RADIUS  SERVER  GROUP  NAME>>
aaa authorization exec default local group <<RADIUS  SERVER  GROUP  NAME>>
```