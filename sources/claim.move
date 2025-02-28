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
use sui_passport::utils::{Version, check_version};

const PK: vector<u8> = vector[185, 198, 238, 22, 48, 
    239, 62, 113, 17, 68, 166, 72, 219, 6, 187, 178, 
    40, 79, 114, 116, 207, 190, 229, 63, 252, 238, 80, 
    60, 193, 164, 146, 0];


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
    version: &Version,
    clock: &Clock,
    ctx: &mut TxContext
) {
    let sender = ctx.sender();
    let stamp = new(event, name, ctx);
    check_version(version);

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

    show_stamp(passport, &stamp, version, clock);
    transfer_stamp(stamp, sender);
}