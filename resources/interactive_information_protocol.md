Built in interactive inductive protocol
1.The sensors capture the coordinates information by monitoringtheUDPport: port 25000
2.Communication protocol TXT description:
For example ,it is 4 points TXT (86 55 01 00 01 00 1D 01 05 00 00 00),let’s see the first row ,first twobytesis86and 55,will keep changing ,then the third bytes 01 00,leave it alone ,you can see the fourth byteis 0100again ,hereby 01 00 represents how many points in this frame (01 00 means 1 point in the frame ,similar 0200means 2 points in the frame),the next 1D 01 represents ‘X ’coordinates ，05 00 represents ‘Y’ coordinates.Thesecond row is similar . A longer TXT example again (CA 56 01 00 02 00 F5 00 05 00 FF 00 0F 00),as same ,we begin fromthe fourthbytes0200 means that 2 points in the frame ,F5 00 represents the first point’s X coordinates ,05 00 represents thefirstpoint’s Y coordinates ,next bytes FF 00 represents the second point’s X coordinates ,OF 00 represents thesecondpoint’s Y coordinates. The count rule is: low is in front, high is behind.for example ,01 00 ,we need regardit asthehexadecimal 0001,it is there is only 1 point in the frame ,similar 1D 01 regard as hexadecimal 01 1D,0500is0005 ,then transfer them to decimal . Example:
The maximum packet length is 1466 bytes.
Byte Number 1 2 3 4 5 6 7 8 9 10 11 12 13 14
Example1 86 55 01 00 01 00 1D 01 05 00
Meaning (5586)Number
of
Frame(Ignore)
Ignore(0001)Number
of Points in
Frame
(011D)First
Point X
coordinate
(0005)First
Point Y
coordinate
Example2 CA 56 01 00 02 00 F5 00 05 00 FF 00 0F 00
Meaning (56CA)Number
of
Frame(Ignore)
Ignore(0002)Number
of Points in
Frame
(00F5)First
Point X
coordinate
(0005)First
Point Y
coordinate
(00FF)Second
Point X
coordinate
(000F)SecondPointY coordinate