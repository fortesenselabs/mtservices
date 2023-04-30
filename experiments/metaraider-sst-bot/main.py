#!/usr/bin/env python
import click
from src.app import App
# 
#   Main
# 
@click.command()
@click.option('--start', '-s', help='Start App')
def main():
    App().start_app()

if __name__ == "__main__":
    main()
