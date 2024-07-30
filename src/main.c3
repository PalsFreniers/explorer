import tb;

fn void main() {
        Event e;
        Cell c = Cell{.ch=65, .fg=tb::DEFAULT, .bg=tb::DEFAULT};
        int[<2>] pos;
        bool cont = true;
        tb::init(); 
        while(cont) {
                e.poll(); 
                switch(e.type) {
                        case tb::EventType.KEY.code: {
                                switch(e.key) {
                                        case tb::Key.ESC.code: cont = false;
                                        case tb::Key.ARROW_UP.code: pos.y--;
                                        case tb::Key.ARROW_DOWN.code: pos.y++;
                                        case tb::Key.ARROW_LEFT.code: pos.x--;
                                        case tb::Key.ARROW_RIGHT.code: pos.x++;
                                }
                        }
                }
                tb::clear();
                tb::putCell(pos.x, pos.y, &c);
                tb::present();
        }
        tb::shutdown();
}
