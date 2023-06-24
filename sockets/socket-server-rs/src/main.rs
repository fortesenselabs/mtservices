use actix_web::{middleware, web, App, HttpResponse, HttpServer, Responder};
use env_logger::Env;
use serde_json::json;
use log::{info};

#[derive(serde::Deserialize)]
struct PriceCandleRequestData {
    status: String,
    symbol: String,
    timeframe: String,
    open: f64,
    high: f64,
    low: f64,
    close: f64,
    tick_volume: f64,
}

#[derive(serde::Deserialize)]
struct PriceTickRequestData {
    symbol: String,
    timeframe: String,
    data: Vec<f64>,
}

async fn index() -> impl Responder {
    HttpResponse::Ok().body("<h1>Hello, Welcome to the WiseFinance Server!</h1>")
}

async fn price_candle_data(payload: web::Json<PriceCandleRequestData>) -> impl Responder {
    let symbol = &payload.symbol;
    let timeframe = &payload.timeframe;
    let open = &payload.open;
    let high = &payload.high;
    let low = &payload.low;
    let close = &payload.close;

    let response_json = json!({
        "symbol": symbol,
        "timeframe": timeframe,
        "open": open,
        "high": high,
        "low": low,
        "close": close
    });

    info!("{}", response_json);

    HttpResponse::Ok()
        .content_type("application/json")
        .json(response_json)
}

async fn price_tick_data(payload: web::Json<PriceTickRequestData>) -> impl Responder {
    let symbol = &payload.symbol;
    let timeframe = &payload.timeframe;
    let data = &payload.data;

    let response_json = json!({
        "symbol": symbol,
        "timeframe": timeframe,
        "data": data
    });

    info!("{}", response_json);

    HttpResponse::Ok()
        .content_type("application/json")
        .json(response_json)
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    let address = "127.0.0.1";
    let port = 9090;

    env_logger::Builder::from_env(Env::default().default_filter_or("debug")).init();

    let server = HttpServer::new(|| {
        App::new()
            .wrap(middleware::Logger::default())
            .service(web::resource("/").to(index))
            .service(web::resource("/price/bar").route(web::post().to(price_candle_data)))
            .service(web::resource("/price/tick").route(web::post().to(price_tick_data)))
    })
    .bind(format!("{}:{}", address, port))?
    .run();

    info!("Server running on http://{}:{}", address, port);

    server.await
}
