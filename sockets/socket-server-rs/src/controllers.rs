use actix_web::{web, HttpResponse};
use serde_json::json;
use serde::Deserialize;
use log::info;


#[derive(Deserialize)]
pub struct BaseEvent<T> {
    event: String,
    data: T,
}

// Other structs
#[derive(Deserialize)]
pub struct BarData {
    bar: Vec<Vec<f64>>,
    symbol: String,
    timeframe: String,
}

#[derive(Deserialize)]
pub struct TickData {
    symbol: String,
    timeframe: String,
    tick: Vec<f64>,
}

pub async fn index() -> HttpResponse {
    // Construct the response JSON
    let response = json!({
            "message": "Hello, Welcome to the Wisefinance MT Server!",
        });

    // Return the response with JSON content type
    HttpResponse::Ok()
        .content_type("application/json")
        .json(response)
}

pub async fn bar_price_data(payload: web::Json<BaseEvent<BarData>>) -> HttpResponse {
    // Access the payload data
    let _event = &payload.event;
    let data = &payload.data; // for data.bar [time(timestamp), open, high, low, close, tick_volume, spread, real_volume]

    // let symbol = &data.symbol;
    // let timeframe = &data.timeframe;

    // send data to DB 
    // Construct the response JSON
    // let response = json!({
    //     "symbol": symbol,
    //     "timeframe": timeframe,
    //     "open": open,
    //     "high": high,
    //     "low": low,
    //     "close": close
    // });

    // Construct the response JSON
    let response = json!({
        "message": format!("Data Received for symbol: {} -> {} -> {:?}", data.symbol, data.timeframe, data.bar),
    });

    info!("[BAR] Data Received: {}", response);

    // Return the response with JSON content type
    HttpResponse::Ok()
        .content_type("application/json")
        .json(response)
}

pub async fn tick_price_data(payload: web::Json<BaseEvent<TickData>>) -> HttpResponse {
    // Access the payload data
    let _event = &payload.event;
    let data = &payload.data; // for data.tick [time(timestamp), bid, ask]

    // send data to DB 
    // let response = json!({
    //     "symbol": symbol,
    //     "timeframe": timeframe,
    //     "data": data
    // });

    // Construct the response JSON
    let response = json!({
        "message": format!("Data Received for symbol: {} -> {} -> {:?}", data.symbol, data.timeframe, data.tick),
    });

    info!("[TICK] Data Received: {}", response);

    // Return the response with JSON content type
    HttpResponse::Ok()
        .content_type("application/json")
        .json(response)
}
