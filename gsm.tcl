set opt(ecn) 0 ;
set opt(window) 30 ;
set opt(type) umts ; 
set opt(minth) 5 ;
set opt(maxth) 10 ;
set opt(adaptive) 1 ; 
#gsm 9600
set bwDL(umts) 384000
set bwUL(umts) 64000
#gsm .500
set propDL(umts) .150
set propUL(umts) .150
set buf(umts) 10
#SET 11 params

set ns [new Simulator]
set tf [open out.tr w]
set nf [open out1.nam w]
$ns trace-all $tf
$ns namtrace-all $nf

set nodes(s) [$ns node]
set nodes(bs1) [$ns node]
set nodes(ms) [$ns node]
set nodes(bs2) [$ns node]
set nodes(d) [$ns node]

proc cell_topo {} {
global ns nodes
$ns duplex-link $nodes(s) $nodes(bs1) 3Mbps 10ms DropTail
$ns duplex-link $nodes(bs1) $nodes(ms) 1Mbps 1ms RED
$ns duplex-link $nodes(ms) $nodes(bs2) 1Mbps 1ms RED
$ns duplex-link $nodes(bs2) $nodes(d) 3Mbps 50ms DropTail 
puts "Cell Topology"
}

proc set_link_params {t} {
global ns nodes bwUL bwDL propUL propDL buf
$ns bandwidth $nodes(bs1) $nodes(ms) $bwDL($t) simplex
$ns bandwidth $nodes(ms) $nodes(bs1) $bwUL($t) simplex
$ns bandwidth $nodes(bs2) $nodes(ms) $bwDL($t) simplex
$ns bandwidth $nodes(ms) $nodes(bs2) $bwUL($t) simplex
$ns delay $nodes(bs1) $nodes(ms) $propDL($t) simplex
$ns delay $nodes(ms) $nodes(bs1) $propDL($t) simplex
$ns delay $nodes(bs2) $nodes(ms) $propDL($t) simplex
$ns delay $nodes(ms) $nodes(bs2) $propDL($t) simplex
$ns queue-limit $nodes(bs1) $nodes(ms) $buf($t)
$ns queue-limit $nodes(ms) $nodes(bs1) $buf($t)
$ns queue-limit $nodes(bs2) $nodes(ms) $buf($t)
$ns queue-limit $nodes(ms) $nodes(bs2) $buf($t)
}

Queue/RED set summarystats_ true
Queue/DropTail set summarystats_ true

Queue/RED set adaptive_ $opt(adaptive)
Queue/RED set q_weight_ 0.0
Queue/RED set thresh_ $opt(minth)
Queue/RED set maxthresh_ $opt(maxth)

Queue/DropTail set shrink_drops_ true

Agent/TCP set ecn_ $opt(ecn)
Agent/TCP set window_ $opt(window)

DelayLink set avoidReordering_ true

switch $opt(type) {
gsm - gprs - umts {cell_topo}
}

set_link_params $opt(type)

$ns insert-delayer $nodes(bs1) $nodes(ms) [new Delayer]
$ns insert-delayer $nodes(ms) $nodes(bs1) [new Delayer]
$ns insert-delayer $nodes(bs2) $nodes(ms) [new Delayer]
$ns insert-delayer $nodes(ms) $nodes(bs2) [new Delayer]

#TODO 
set tcp1 [$ns create-connection TCP/Sack1 $nodes(s) TCPSink/Sack1 $nodes(d) 0]
set ftp1 [[set tcp1] attach-app FTP]

$ns at 0.5 "$ftp1 start"
$ns at 100 "stop"

proc stop {} {
global ns nf tf
$ns flush-trace
close $nf
close $tf
exec nam out1.nam &
exit 0
}
$ns run 