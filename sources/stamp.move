module sui_passport::stamp;

use std::{
    string::String
};
use sui::{
    table::{Self, Table},
    vec_set::{Self, VecSet},
    dynamic_field as df,
    event::emit,
    display,
    package
};

public struct STAMP has drop {}

public struct SuperAdminCap has key {
    id: UID,
}

public struct AdminSet has key {
    id: UID,
    admin: VecSet<address>,
}

public struct EventRecord has key {
    id: UID,
    record: Table<String, ID>,
}

#[allow(unused_field)]
public struct Event has key {
    id: UID,
    event: String,
    description: String,
    stamp_type: vector<String>,
}

#[allow(unused_field)]
public struct StampMintInfo has store {
    name: String,
    count: u32,
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

public struct SetEventStamp has copy, drop {
    event: ID,
    name: String,
    image_url: String,
    points: u64,
    description: String,
}

fun init(otw: STAMP, ctx: &mut TxContext) {
    let deployer = ctx.sender();
    let super_admin = SuperAdminCap { id: object::new(ctx) };
    transfer::transfer(super_admin, deployer);
    let admin_set = AdminSet {
        id: object::new(ctx),
        admin: vec_set::empty<address>(),
    };
    transfer::share_object(admin_set);

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

    let event_record = EventRecord {
        id: object::new(ctx),
        record: table::new<String, ID>(ctx),
    };
    transfer::share_object(event_record);
}

public fun set_admin(_super_admin: &SuperAdminCap, admin_set: &mut AdminSet, admin_address: address) {
    admin_set.admin.insert(admin_address);
}

public fun remove_admin(_super_admin: &SuperAdminCap, admin_set: &mut AdminSet, admin_address: address) {
    admin_set.admin.remove(&admin_address);
}

public(package) fun check_admin(admin_set: &AdminSet, ctx: &TxContext) {
    assert!(admin_set.admin.contains(&ctx.sender()));
}

public fun create_event(
    admin_set: &AdminSet,
    event_record: &mut EventRecord,
    event: String, 
    description: String,
    ctx: &mut TxContext
): Event {
    check_admin(admin_set, ctx);
    let new_event = Event {
        id: object::new(ctx),
        event,
        description,
        stamp_type: vector::empty(),
    };
    event_record.record.add(event, object::id(&new_event));
    new_event
}

public fun share_event(
    event: Event
) {
    transfer::share_object(event);
}

public fun set_event_name(
    admin_set: &AdminSet,
    event: &mut Event, 
    name: String,
    ctx: &TxContext,
) {
    check_admin(admin_set, ctx);
    event.event = name;
}

public fun set_event_description(
    admin_set: &AdminSet,
    event: &mut Event, 
    description: String,
    ctx: &TxContext,
) {
    check_admin(admin_set, ctx);
    event.description = description;
}

public fun set_event_stamp(
    admin_set: &AdminSet,
    event: &mut Event, 
    name: String,
    image_url: String,
    points: u64,
    description: String,
    ctx: &TxContext,
) {
    check_admin(admin_set, ctx);
    assert!(!event.stamp_type.contains(&name));
    event.stamp_type.push_back(name);

    let stamp_info = StampMintInfo {
        name,
        count: 0,
        image_url,
        points,
        description
    };
    df::add<String, StampMintInfo>(&mut event.id, name, stamp_info);
    emit(SetEventStamp {
        event: object::id(event),
        name,
        image_url,
        points,
        description,
    });
}

public fun remove_event_stamp(
    admin_set: &AdminSet,
    event: &mut Event, 
    name: String,
    ctx: &TxContext,
) {
    check_admin(admin_set, ctx);
    let stamp_info = df::borrow<String, StampMintInfo>(&event.id, name);
    assert!(stamp_info.count == 0);
    let stamp_info = df::remove<String, StampMintInfo>(&mut event.id, name);
    let StampMintInfo { .. } = stamp_info;
    let index = event.stamp_type.find_index!(|e| *e == name).destroy_some();
    event.stamp_type.swap_remove(index);
}

public fun remove_event_stamp_v2(
    admin_set: &AdminSet,
    event_record: &mut EventRecord,
    event: Event, 
    name: String,
    ctx: &TxContext,
) {
    check_admin(admin_set, ctx);
    let stamp_info = df::borrow<String, StampMintInfo>(&event.id, name);
    assert!(stamp_info.count == 0);
    event_record.record.remove(event.event);
    let Event {
        id,
        ..
    } = event;
    object::delete(id);
}

public fun event_stamp_type(event: &Event): vector<String> {
    event.stamp_type
}

public(package) fun new(
    event: &mut Event,
    name: String,
    ctx: &mut TxContext
): Stamp {
    assert!(event.stamp_type.contains(&name));
    let stamp_info = df::borrow_mut<String, StampMintInfo>(&mut event.id, name);
    stamp_info.count = stamp_info.count + 1;
    let mut stamp_name = name;
    stamp_name.append(b"#".to_string());
    stamp_name.append(stamp_info.count.to_string());
    Stamp {
        id: object::new(ctx),
        name: stamp_name,
        image_url: stamp_info.image_url,
        points: stamp_info.points,
        event: event.event,
        description: stamp_info.description,
    }
}

public(package) fun transfer_stamp(
    stamp: Stamp,
    recipient: address
) {
    transfer::transfer(stamp, recipient);
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

public fun event_name(event: &Event): String {
    event.event
}