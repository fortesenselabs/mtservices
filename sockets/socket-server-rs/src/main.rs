use actix_web::{middleware, web, App, HttpServer};
use env_logger::Env;
use log::info;

mod controllers;

const HOST: &str = "127.0.0.1";
const PORT: i32 = 9090;

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    env_logger::Builder::from_env(Env::default().default_filter_or("debug")).init();

    let server = HttpServer::new(|| {
        App::new()
            .wrap(middleware::Logger::default())
            .service(web::resource("/").to(controllers::index))
            .service(web::resource("/api/price/stream/bar").route(web::post().to(controllers::bar_price_data)))
            .service(web::resource("/api/price/stream/tick").route(web::post().to(controllers::tick_price_data)))
    })
    .bind(format!("{}:{}", HOST, PORT))?
    .run();

    info!("Server running on http://{}:{}", HOST, PORT);

    server.await
}
