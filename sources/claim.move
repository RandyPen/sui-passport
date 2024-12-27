module sui_passport::claim;

use std::{
    string::String
};
use sui::{
    clock::Clock,
    event::emit,
    bcs,
    hash,
    ed25519
};
use sui_passport::sui_passport::{
    SuiPassport,
    show_stamp,
    last_time
};
use sui_passport::stamp::{
    Event,
    new,
    event_name,
    transfer_stamp
};

const PK: vector<u8> = vector[93,51,18,189,20,112,56,203,181,234,192,63,104,62,182,60,129,208,40,0,33,50,233,136,70,68,220,141,131,226,106,38];


public struct ClaimStampEvent has copy, drop {
    recipient: address,
    event: String,
    stamp: ID,
}

public struct ClaimStampInfo has drop {
    passport: ID,
    last_time: u64,
}

public fun claim_stamp(
    event: &mut Event,
    passport: &mut SuiPassport,
    name: String,
    sig: vector<u8>,
    clock: &Clock,
    ctx: &mut TxContext
) {
    let sender = ctx.sender();
    let stamp = new(event, name, ctx);

    let claim_stamp_info = ClaimStampInfo {
        passport: object::id(passport),
        last_time: last_time(passport),
    };

    let byte_data = bcs::to_bytes(&claim_stamp_info);
    let hash_data = hash::keccak256(&byte_data);
    let pk = PK;
    let verify = ed25519::ed25519_verify(&sig, &pk, &hash_data);
    assert!(verify == true, 1);

    emit(ClaimStampEvent {
        recipient: sender,
        event: event_name(event),
        stamp: object::id(&stamp),
    });

    show_stamp(passport, &stamp, clock);
    transfer_stamp(stamp, sender);
}