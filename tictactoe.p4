/* Tic tac toe
 * Protocol header:
 *
 *        0                1                  2              3
 * +----------------+----------------+----------------+---------------+
 * |      P         |       4        |     Version    |     C        |
 * +----------------+----------------+----------------+---------------+
 * |                               location                           |
 * +----------------+----------------+----------------+---------------+
 * |                         responselocation                         |
 * +----------------+----------------+----------------+---------------+
 * |                              Result                              |
 * +----------------+----------------+----------------+---------------+
 *
 * P is an ASCII Letter 'P' (0x50)
 * 4 is an ASCII Letter '4' (0x34)
 * Version is currently 0.1 (0x01)
 
 
 *C is counter (number of plays which have happened): if this is at 9 then all squares will have been filled.
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
	bit<8> op;
	bit<32> location;
	bit<32> responselocation;
	bit<32> res;
}

//Struct of headers

struct headers {
    ethernet_t   ethernet;
    tictactoe_t     tictactoe;
}

//Struct of metadata

struct metadata {
	bit <32> empty;
	bit <32> emptyr;
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
	
	register<bit<64>>(9) state;
	
	action send_back(bit<64> result) {
    	        macAddr_t tmp_mac;
         
		hdr.tictactoe.res = result;
         
		tmp_mac = hdr.ethernet.dstAddr;
		hdr.ethernet.dstAddr = hdr.ethernet.srcAddr;
		hdr.ethernet.srcAddr = tmp_mac;
		
		standard_metadata.egress_spec = standard_metadata.ingress_port;
	}    

// Checking if the chosen spot is open
// If the location in question (for either player 1 or 2) is labelled as empty, send back positive response (how?)
// If location not empty, drop
    
	action checkopen() {
		index = header.tictactoe.location - 1;
		state.read(ctstate,index);
		if (cstate == 0) {
			meta.empty = 1;
			state.write(index,1);
		} else {
		drop()
		}
		}
	     
     }

	action checkopenresponse() {
		index = header.tictactoe.responselocation - 1;
		state.read(ctstate,index);
		if (cstate == 0) {
			meta.emptyr = 1;
		} else {
		meta.emptyr = 0;
		}
		}
	
	}

     
// Choosing coordinates for response
// Starting with adding 1 unless the number is 9, in which case 1 will be chosen.

	action response(){
		if (header.tictactoe.location == 9) {
			header.tictactoe.responselocation = 1;
		} else {
		 header.tictactoeresponse.location = header.tictactoe.location +1;
		}
		
		index = header.tictactoe.responselocation - 1;
		
	// This bit could keep looping if none of the locations are empty. Need to have some kind of counter for number of plays??	
		checkopenresponse();
		if (meta.emptyr == 1) {
			state.write(index,1);
		} else {
			response();
		}
	}

// Drop action if invalid or spot taken

    action drop() {
        mark_to_drop(standard_metadata);
    }
	     
//table

	table toApply {
	key = {
            //??????: ?????;
        }
        
	actions = {
	send_back
	checkopen;
	checkopenresponse;
	response;
	drop;
	}
	
	
	
	}
	
//Apply table only if tictactoe is valid AND if the slot is empty

	apply {
        if (hdr.tictactoe.isValid()) {
            	if(meta.empty ==1) {
            	toApply.apply();
        	} else {
        	drop();
        	}
	else {
	operation_drop();
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
