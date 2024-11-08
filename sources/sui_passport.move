module sui_passport::sui_passport;

use std::{
    string::String
};
use sui::{
    table::{Self, Table},
    clock::{Self, Clock},
    event::emit,
    display,
    package
};
use sui_passport::stamp::{Self, Stamp};

public struct SUI_PASSPORT has drop {}

#[allow(unused_field)]
public struct SuiPassport has key {
    id: UID,
    name: String,
    avatar: String,
    introduction: String,
    exhibit: vector<ID>,
    collections: Table<ID, bool>,
    points: u64,
    x: String,
    github: String,
    email: String,
    last_time: u64,
}

public struct SuiPassportRecord has key {
    id: UID,
    record: Table<address, bool>,
}

public struct MintPassportEvent has copy, drop {
    sender: address,
    passport: ID,
}

public struct DropPassportEvent has copy, drop {
    sender: address,
    passport: ID,
}

public struct EditPassportEvent has copy, drop {
    sender: address,
    passport: ID,
}

fun init(otw: SUI_PASSPORT, ctx: &mut TxContext) {
    let deployer = ctx.sender();
    let sui_passport_record = SuiPassportRecord {
        id: object::new(ctx),
        record: table::new<address, bool>(ctx),
    };
    transfer::share_object(sui_passport_record);

    let keys = vector[
        b"name".to_string(),
        b"image_url".to_string(),
        b"project_url".to_string(),
        b"description".to_string(),
    ];

    let mut image_url: vector<u8> = b"https://suipassport.com/objectId/";
    image_url.append(b"{id}");
    let project_url: vector<u8> = b"https://suipassport.com/project/";

    let values = vector[
        b"{name}".to_string(),
        image_url.to_string(),
        project_url.to_string(),
        b"Get your Sui Passport, start exploring the Sui Universe.".to_string(),
    ];

    let publisher = package::claim(otw, ctx);
    let mut passport_display = display::new_with_fields<SuiPassport>(
        &publisher,
        keys,
        values,
        ctx,
    );

    passport_display.update_version();
    transfer::public_transfer(publisher, deployer);
    transfer::public_transfer(passport_display, deployer);
}

public fun mint_passport(
    record: &mut SuiPassportRecord, 
    name: String,
    avatar: String,
    introduction: String,
    x: String,
    github: String,
    email: String,
    clock: &Clock,
    ctx: &mut TxContext
) {
    let sender = ctx.sender();
    table::add<address, bool>(&mut record.record, sender, true);
    let passport = SuiPassport {
        id: object::new(ctx),
        name,
        avatar,
        introduction,
        exhibit: vector::empty<ID>(),
        collections: table::new<ID, bool>(ctx),
        points: 0,
        x,
        github,
        email,
        last_time: clock::timestamp_ms(clock),
    };
    emit(MintPassportEvent {
        sender,
        passport: object::id(&passport),
    });
    transfer::transfer(passport, sender);
}

public fun drop_passport(
    record: &mut SuiPassportRecord, 
    passport: SuiPassport,
    ctx: &mut TxContext
) {
    let sender = ctx.sender();
    table::remove<address, bool>(&mut record.record, sender);

    emit(DropPassportEvent {
        sender,
        passport: object::id(&passport),
    });
    let SuiPassport {
        id,
        collections,
        ..
    } = passport;
    object::delete(id);
    table::drop<ID, bool>(collections);
}

public fun edit_passport(
    passport: &mut SuiPassport,
    mut name: Option<String>,
    mut avatar: Option<String>,
    mut introduction: Option<String>,
    mut x: Option<String>,
    mut github: Option<String>,
    mut email: Option<String>,
    ctx: &TxContext
) {
    if (name.is_some()) {
        passport.name = option::extract(&mut name);
    };
    if (avatar.is_some()) {
        passport.avatar = option::extract(&mut avatar);
    };
    if (introduction.is_some()) {
        passport.introduction = option::extract(&mut introduction);
    };
    if (x.is_some()) {
        passport.x = option::extract(&mut x);
    };
    if (github.is_some()) {
        passport.github = option::extract(&mut github);
    };
    if (email.is_some()) {
        passport.email = option::extract(&mut email);
    };

    emit(EditPassportEvent {
        sender: ctx.sender(),
        passport: object::id(passport),
    });
}

public fun show_stamp(passport: &mut SuiPassport, stamp: &Stamp) {
    let stamp_id = object::id(stamp);

    if (table::contains<ID, bool>(&passport.collections, stamp_id)) {
        let display = &mut passport.collections[stamp_id];
        *display = true;
    } else {
        passport.points = passport.points + stamp::points(stamp);
        table::add<ID, bool>(&mut passport.collections, stamp_id, true);
    };
}

public fun hide_stamp(passport: &mut SuiPassport, stamp: &Stamp) {
    let stamp_id = object::id(stamp);

    if (table::contains<ID, bool>(&passport.collections, stamp_id)) {
        let display = &mut passport.collections[stamp_id];
        *display = false;
    } else {
        passport.points = passport.points + stamp::points(stamp);
        table::add<ID, bool>(&mut passport.collections, stamp_id, false);
    };
}