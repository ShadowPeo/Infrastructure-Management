#How to Enable AAA Radius Authentication on Cisco IOS Switches

##Enable AAA Authentication
`aaa new-model`

**Depending on what IOS version the switch is running the code below will be different, if the new method does not work, try the old method**

**N2128PX-ON**

```
radius server auth <<RADIUS SERVER IP>>
name "<<RADIUS SERVER NAME>>"
key <<RADIUS SERVER CLIENT KEY>>
exit
```

**N4032F**

```
radius server host <<RADIUS SERVER IP>>
name "<<RADIUS SERVER NAME>>"
key <<RADIUS SERVER CLIENT KEY>>
exit
```

**From here on the code is the same**

##Create AAA Control Groups - Checks local first, then RADIUS otherwise will fail if RADIUS is checked first will not fall back nicely to local

```
aaa authentication login "VTY_authen" local radius
aaa authorization exec "VTY_author" local radius
```

##Enable SSH AAA Auth
```
line ssh
login authentication VTY_authen
exit
```

##Enable HTTP(S) AAA Auth
```
ip http authentication local radius
```
##Console Authentication
```  
line console
login authentication VTY_authen
exit
``` 