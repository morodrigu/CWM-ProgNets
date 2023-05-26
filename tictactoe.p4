/* Tic tac toe
 * P is an ASCII Letter 'P' (0x50)
 * 4 is an ASCII Letter '4' (0x34)
 * Version is currently 0.1 (0x01)
 *
 * The device receives a packet, performs the requested operation, fills in the
 * result and if the move was valid, displays the result on the raspberry pi.
 *
 * If an unknown operation is specified or the header is not valid, the packet
 * is dropped
 */

#include <core.p4>
#include <v1model.p4>

//Defining headers

 typedef bit<48> macAddr_t;
 typedef bit<9>  egressSpec_t;
 
//Ethernet header

 header ethernet_t {
    bit<48> dstAddr;
    bit<48> srcAddr;
    bit<16> etherType;
}

//Constants

const bit<16> TTT_ETYPE = 0x1234;
const bit<8>  TTT_P     = 0x50;   // 'P'
const bit<8>  TTT_4     = 0x34;   // '4'
const bit<8>  TTT_VER   = 0x01;   // v0.1

//Header

header tictactoe_t {
	bit<8> P;
	bit<8> four;
	bit<8> ver;
	bit<8> s1;
	bit<8> s2;
	bit<8> s3;
	bit<8> s4;
	bit<8> s5;
	bit<8> s6;
	bit<8> s7;
	bit<8> s8;
	bit<9> s9;
	bit<32> result;
}

//Struct of headers

struct headers {
    ethernet_t   ethernet;
    tictactoe_t     tictactoe;
}

//Struct of metadata

struct metadata {
}


//Parser

parser MyParser(packet_in packet,
                out headers hdr,
                inout metadata meta,
                inout standard_metadata_t standard_metadata) {
    state start {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            TTT_ETYPE : check_ttt;
            default : accept;
        }
    }

    state check_ttt {
        transition select(packet.lookahead<tictactoe_t>().P,
        packet.lookahead<tictactoe_t>().four,
        packet.lookahead<tictactoe_t>().ver) {
            (TTT_P, TTT_4, TTT_VER) : parse_ttt;
            default : accept;
        }
    }

    state parse_ttt {
        packet.extract(hdr.tictactoe);
        transition accept;
    }
}

//Checksum verification

control MyVerifyChecksum(inout headers hdr,
                         inout metadata meta) {
    apply { }
}

//Ingress processing

control MyIngress(inout headers hdr,
                  inout metadata meta,
                  inout standard_metadata_t standard_metadata) {
	
	action send_back(bit<32> result) {
    	        macAddr_t tmp_mac;
         
		hdr.tictactoe.res = result;
         
		tmp_mac = hdr.ethernet.dstAddr;
		hdr.ethernet.dstAddr = hdr.ethernet.srcAddr;
		hdr.ethernet.srcAddr = tmp_mac;
		
		standard_metadata.egress_spec = standard_metadata.ingress_port;
	}    



	action operation1(){
		send_back(1);
		}
	action operation2(){
		send_back(2);
		}
	action operation3(){
		send_back(3);
		}
	action operation4(){
		send_back(4);
		}
	action operation5(){
		send_back(5);
		}
	action operation6(){
		send_back(6);
		}
	action operation7(){
		send_back(7);
		}
	action operation8(){
		send_back(8);
		}
	action operation9(){
		send_back(9);
		}
	action winner1(){
		send_back(10);
		}
	action winner2(){
		send_back(11);
		}
		
	action firstempty(){
		
		}										
		
// Drop action if invalid or spot taken

	action drop() {
	mark_to_drop(standard_metadata);
	}



	     
//table

	table toApply {
	key = {
            {s1,s2,s3,s4,s5,s6,s7,s8,s9} : exact;
//            s1 :exact;
//            s2 :exact;
//            s3 :exact;
//            s4 :exact;
//            s5 :exact;
//            s6 :exact;
//            s7 :exact;
//            s8 :exact;
//            s9 :exact;
        }
        
	actions = {
	send_back;
	operation1;
	operation2;
	operation3;
	operation4;
	operation5;
	operation6;
	operation7;
	operation8;
	operation9;
	winner1;
	winner2;
	firstempty;
	drop;
	}
	
        const default_action = firstempty();
        const entries = {
        	{1,0,0,0,0,0,0,0,0} : operation5;
        	{0,1,0,0,0,0,0,0,0} : operation5;
        	{0,0,1,0,0,0,0,0,0} : operation5;
        	{0,0,0,1,0,0,0,0,0} : operation5;
        	{0,0,0,0,1,0,0,0,0} : operation4;
        	{0,0,0,0,0,1,0,0,0} : operation5;
        	{0,0,0,0,0,0,1,0,0} : operation5;
        	{0,0,0,0,0,0,0,1,0} : operation5;
        	{0,0,0,0,0,0,0,0,1} : operation5;    	
        	
        }	
	
	
	}


	apply {
        if (hdr.tictactoe.isValid()) {
            	toApply.apply();
	} else {
	drop();
        }
        }
	}




	
// Egress processing

control MyEgress(inout headers hdr,
                 inout metadata meta,
                 inout standard_metadata_t standard_metadata) {
    apply { }
}

//Checksum computation

control MyComputeChecksum(inout headers hdr, inout metadata meta) {
    apply { }

//Deparser

control MyDeparser(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.ethernet);
        packet.emit(hdr.tictactoe);
    }
}


//Switch

V1Switch(
MyParser(),
MyVerifyChecksum(),
MyIngress(),
MyEgress(),
MyComputeChecksum(),
MyDeparser()
) main;
