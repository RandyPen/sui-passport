module sui_passport::stamp;

use std::{
    string::String
};
use sui::{
    table::{Self, Table},
    clock::{Self, Clock},
    dynamic_field as df,
    event::emit,
    display,
    package
};
use sui_passport::sui_passport::{
    SuiPassport,
    set_last_time
};

public struct STAMP has drop {}

public struct AdminCap has key, store {
    id: UID,
}

#[allow(unused_field)]
public struct OnlineEvent has key {
    id: UID,
    event: String,
    stamp_type: vector<String>,
}

#[allow(unused_field)]
public struct StampMintInfo has store {
    name: String,
    count: u64,
    image_url: String,
    points: u64,
    description: String,
}

public struct Stamp has key {
    id: UID,
    name: String,
    image_url: String,
    points: u64,
    event: String,
    description: String,
}

fun init(otw: STAMP, ctx: &mut TxContext) {
    let deployer = ctx.sender();
    let admin_cap = AdminCap { id: object::new(ctx) };
    transfer::public_transfer(admin_cap, deployer);

    let keys = vector[
        b"name".to_string(),
        b"image_url".to_string(),
        b"event".to_string(),
        b"description".to_string(),
    ];

    let values = vector[
        b"{name}".to_string(),
        b"{image_url}".to_string(),
        b"{event}".to_string(),
        b"{description}".to_string(),
    ];

    let publisher = package::claim(otw, ctx);
    let mut stamp_display = display::new_with_fields<Stamp>(
        &publisher,
        keys,
        values,
        ctx,
    );

    stamp_display.update_version();
    transfer::public_transfer(publisher, deployer);
    transfer::public_transfer(stamp_display, deployer);
}

public fun set_admin(_admin: &AdminCap, recipient: address, ctx: &mut TxContext) {
    let admin_cap = AdminCap { id: object::new(ctx) };
    transfer::public_transfer(admin_cap, recipient);
}

public fun open_online_event(
    _admin: &AdminCap, 
    event: String, 
    ctx: &mut TxContext
) {
    let online_event = OnlineEvent {
        id: object::new(ctx),
        event,
        stamp_type: vector::empty(),
    };
    transfer::share_object(online_event);
}

public fun set_online_event_description(
    _admin: &AdminCap, 
    online_event: &mut OnlineEvent, 
    event: String
) {
    online_event.event = event;
}

public fun set_online_event_stamp(
    _admin: &AdminCap, 
    online_event: &mut OnlineEvent, 
    name: String,
    image_url: String,
    points: u64,
    description: String,
) {
    assert!(!vector::contains(&online_event.stamp_type, &name));
    online_event.stamp_type.push_back(name);

    let stamp_info = StampMintInfo {
        name,
        count: 0,
        image_url,
        points,
        description
    };
    df::add<String, StampMintInfo>(&mut online_event.id, name, stamp_info);
}

public fun remove_online_event_stamp(
    _admin: &AdminCap, 
    online_event: &mut OnlineEvent, 
    name: String,
) {
    let stamp_info = df::borrow<String, StampMintInfo>(&online_event.id, name);
    assert!(stamp_info.count == 0);
    let stamp_info = df::remove<String, StampMintInfo>(&mut online_event.id, name);
    let StampMintInfo { .. } = stamp_info;
    let index = online_event.stamp_type.find_index!(|e| *e == name).destroy_some();
    online_event.stamp_type.swap_remove(index);
}

public fun name(stamp: &Stamp): String {
    stamp.name
}

public fun image_url(stamp: &Stamp): String {
    stamp.image_url
}

public fun points(stamp: &Stamp): u64 {
    stamp.points
}

public fun description(stamp: &Stamp): String {
    stamp.description
}

public fun event(stamp: &Stamp): String {
    stamp.event
}