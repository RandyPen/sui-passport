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
use sui_passport::version::{Version, check_version};

public struct SUI_PASSPORT has drop {}

// ====== Constants =======
const EXHIBIT_MAX: u64 = 3;

// ====== Errors =======
const ETooMuchExhibit: u64 = 1000;
const EInvalidExhibit: u64 = 1001;

#[allow(unused_field)]
public struct SuiPassport has key {
    id: UID,
    name: String,
    avatar: String,
    introduction: String,
    exhibit: vector<ID>,
    collections: Table<ID, bool>,
    points: u64,
    last_time: u64,
}

public struct SuiPassportRecord has key {
    id: UID,
    record: Table<address, u64>,
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
        record: table::new<address, u64>(ctx),
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
    let project_url: vector<u8> = b"https://suipassport.com/";

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
    version: &Version,
    clock: &Clock,
    ctx: &mut TxContext
) {
    let sender = ctx.sender();
    check_version(version);
    table::add<address, u64>(&mut record.record, sender, 0);
    let passport = SuiPassport {
        id: object::new(ctx),
        name,
        avatar,
        introduction,
        exhibit: vector::empty<ID>(),
        collections: table::new<ID, bool>(ctx),
        points: 0,
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
    version: &Version,
    ctx: &mut TxContext
) {
    let sender = ctx.sender();
    check_version(version);
    table::remove<address, u64>(&mut record.record, sender);

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
    version: &Version,
    clock: &Clock,
    ctx: &TxContext
) {
    check_version(version);
    if (name.is_some()) {
        passport.name = option::extract(&mut name);
    };
    if (avatar.is_some()) {
        passport.avatar = option::extract(&mut avatar);
    };
    if (introduction.is_some()) {
        passport.introduction = option::extract(&mut introduction);
    };
    passport.last_time = clock::timestamp_ms(clock);

    emit(EditPassportEvent {
        sender: ctx.sender(),
        passport: object::id(passport),
    });
}

public fun show_stamp(
    passport: &mut SuiPassport, 
    stamp: &Stamp, 
    version: &Version,
    clock: &Clock
) {
    let stamp_id = object::id(stamp);
    check_version(version);

    if (passport.collections.contains(stamp_id)) {
        let display = &mut passport.collections[stamp_id];
        *display = true;
    } else {
        passport.points = passport.points + stamp::points(stamp);
        passport.collections.add(stamp_id, true);
    };
    passport.last_time = clock::timestamp_ms(clock);
}

public fun hide_stamp(
    passport: &mut SuiPassport, 
    stamp: &Stamp, 
    version: &Version,
    clock: &Clock
) {
    let stamp_id = object::id(stamp);
    check_version(version);

    if (passport.collections.contains(stamp_id)) {
        let display = &mut passport.collections[stamp_id];
        *display = false;
    } else {
        passport.points = passport.points + stamp::points(stamp);
        passport.collections.add(stamp_id, false);
    };
    passport.last_time = clock::timestamp_ms(clock);
}

public fun set_exhibit(
    passport: &mut SuiPassport, 
    exhibit: vector<ID>, 
    version: &Version,
    clock: &Clock
) {
    let mut i = 0;
    let len = exhibit.length();
    assert!(len <= EXHIBIT_MAX, ETooMuchExhibit);
    check_version(version);

    while (i < len) {
        assert!(passport.collections.contains(exhibit[i]), EInvalidExhibit);
        i = i + 1;
    };

    passport.exhibit = exhibit;
    passport.last_time = clock::timestamp_ms(clock);
}

public(package) fun set_last_time(passport: &mut SuiPassport, clock: &Clock) {
    passport.last_time = clock::timestamp_ms(clock);
}

public fun points(passport: &SuiPassport): u64 {
    passport.points
}

public fun last_time(passport: &SuiPassport): u64 {
    passport.last_time
}

public fun update_points(
    record: &mut SuiPassportRecord, 
    passport: &SuiPassport,
    version: &Version,
    ctx: &TxContext
) {
    check_version(version);
    let points = &mut record.record[ctx.sender()];
    *points = points(passport);
}