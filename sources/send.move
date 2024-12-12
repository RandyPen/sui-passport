module sui_passport::send;

use std::{
    string::String
};
use sui::{
    event::emit
};
use sui_passport::stamp::{
    AdminCap,
    Event,
    new,
    event_name,
    transfer_stamp
};

public struct SendStampEvent has copy, drop {
    recipient: address,
    event: String,
    stamp: ID,
}

public fun send_stamp(
    _admin: &AdminCap, 
    event: &mut Event,
    name: String,
    recipient: address,
    ctx: &mut TxContext
) {
    let stamp = new(event, name, ctx);
    emit(SendStampEvent {
        recipient,
        event: event_name(event),
        stamp: object::id(&stamp),
    });
    transfer_stamp(stamp, recipient);
}

public fun batch_send_stamp(
    _admin: &AdminCap, 
    event: &mut Event,
    name: String,
    mut recipients: vector<address>,
    ctx: &mut TxContext
) {
    let len = vector::length(&recipients);
    let mut i = 0;

    while (i < len) {
        let recipient = vector::pop_back(&mut recipients);
        let stamp = new(event, name, ctx);
        emit(SendStampEvent {
            recipient,
            event: event_name(event),
            stamp: object::id(&stamp),
        });
        transfer_stamp(stamp, recipient);
        i = i + 1;
    };
}
