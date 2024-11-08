module sui_passport::stamp;

use std::{
    string::String
};

public struct Stamp has key {
    id: UID,
    name: String,
    image_url: String,
    points: u64,
    description: String,
    event: String,
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