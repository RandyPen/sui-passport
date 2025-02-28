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
use sui_passport::utils::{Version, check_version};

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
    version: &Version,
    ctx: &mut TxContext
) {
    let stamp = new(event, name, ctx);
    check_version(version);
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
    version: &Version,
    ctx: &mut TxContext
) {
    let len = vector::length(&recipients);
    let mut i = 0;
    check_version(version);

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
