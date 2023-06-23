use actix_web::{middleware, web, App, HttpResponse, HttpServer, Responder};
use env_logger::Env;
use serde_json::json;

async fn index() -> impl Responder {
    HttpResponse::Ok().body("<h1>Hello, Rust HTTP Server!</h1>")
}

async fn price_data(payload: web::Json<PriceRequestData>) -> impl Responder {
    // Access the payload data
    let symbol = &payload.symbol;
    let period = &payload.period;
    let open = &payload.open;
    let high = &payload.high;
    let low = &payload.low;
    let close = &payload.close;

    // Construct the response JSON
    let response_json = json!({
        "symbol": symbol,
        "period": period,
        "open": open,
        "high": high,
        "low": low,
        "close": close
    });

    // Return the response with JSON content type
    HttpResponse::Ok()
        .content_type("application/json")
        .json(response_json)
}

#[derive(serde::Deserialize)]
struct PriceRequestData {
    symbol: String,
    period: String,
    open: f64,
    high: f64,
    low: f64,
    close: f64,
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    let address = "127.0.0.1";
    let port = 9090;

    // Configure logger to print request logs
    env_logger::Builder::from_env(Env::default().default_filter_or("debug")).init();

    let server = HttpServer::new(|| {
        App::new()
            .wrap(middleware::Logger::default()) // Add request logging middleware
            .service(web::resource("/").to(index))
            .service(web::resource("/price/stream").route(web::post().to(price_data)))
    })
    .bind(format!("{}:{}", address, port))?
    .run();

    println!("Server running on http://{}:{}", address, port);

    server.await
}
