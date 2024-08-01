module tb;

fn void write(int x, int y, String str, ushort fg, ushort bg) {
        if(x < 0 || x >= tb::width()) return;
        if(y < 0 || y >= tb::height()) return;
        Cell cell = Cell{.ch=65, .fg=fg, .bg=bg};
        foreach(char c : str) {
                cell.ch = c;
                putCell(x++, y, &cell);
                if(x >= tb::width()) break;
        }
}

fn void writeC(int x, int y, char str, ushort fg, ushort bg) {
        if(x < 0 || x >= tb::width()) return;
        if(y < 0 || y >= tb::height()) return;
        Cell cell = Cell{.ch=str, .fg=fg, .bg=bg};
        putCell(x++, y, &cell);
}

module explorer;
import tb;
import libc;
import std::io::file;
import std::io::path;
import std::os::posix;
import std::core::string;

fn void menu(bool* cont) {
        Event e;
        bool c = true;
        int pos = 0;
        while(c) {
                switch(e.peek(10)) {
                        case tb::EventType.KEY.code: {
                                switch(e.key) {
                                        case tb::Key.ESC.code: c = false;
                                        case tb::Key.ARROW_UP.code: pos--;
                                        case tb::Key.ARROW_DOWN.code: pos++;
                                        case tb::Key.ENTER.code: {
                                                if(pos == 0) c = false;
                                                if(pos == 1) {
                                                        *cont = false;
                                                        c = false;
                                                }
                                        }
                                }
                                break;
                        }
                        default: break;
                }
                if(pos == 2) pos = 0;
                if(pos == -1) pos = 1;
                tb::clear();
                tb::write(0, 0, "continue", tb::DEFAULT, pos == 0 ? tb::RED : tb::DEFAULT);
                tb::write(0, 1, "quit", tb::DEFAULT, pos == 1 ? tb::RED : tb::DEFAULT);
                tb::present();
        }
}

fn ushort getColor(char type) {
        switch(type) {
                case posix::DT_DIR: return tb::GREEN;
                case posix::DT_REG: return tb::YELLOW;
                case posix::DT_LNK: return tb::RED;
                default: return tb::DEFAULT;
        }
}

fn void printCurrentDir(int cursor, int start) {
        ZString currentPath = posix::getcwd(null, 0);
        defer libc::free((void*)currentPath);
        posix::DIRPtr cur = posix::opendir(currentPath);
        defer posix::closedir(cur);
        posix::Posix_dirent* ent = posix::readdir(cur);
        int pos = start;
        while(ent != null) {
                String file = ((ZString)&ent.name).str_view();
                ushort color = getColor(ent.d_type);
                tb::write(0, pos, file, color, cursor == pos ? tb::BLUE : tb::DEFAULT);
                pos++;
                ent = posix::readdir(cur);
        }
}

fn int fileCount() {
        ZString currentPath = posix::getcwd(null, 0);
        defer libc::free((void*)currentPath);
        posix::DIRPtr cur = posix::opendir(currentPath);
        defer posix::closedir(cur);
        posix::Posix_dirent* ent = posix::readdir(cur);
        int pos = 0;
        while(ent != null) {
                pos++;
                ent = posix::readdir(cur);
        }
        return pos;
}

fn Posix_dirent* getEntry(usz cursor, DIRPtr cur) {
        posix::Posix_dirent* ent = posix::readdir(cur);
        int pos = 0;
        while(ent != null && pos < cursor) {
                pos++;
                ent = posix::readdir(cur);
        }
        return ent;
}

distinct Pid = CULong;

extern fn Pid fork();
extern fn Pid Pid.wait(Pid self, CInt* stat_loc, CInt options) @extern("waitpid");
extern fn CInt execv(char *path, char** argv);

fn void openFile(char* file) {
        char** argv = mem::new_array(char*, 3);
        defer mem::free(argv);
        argv[0] = "nano";
        argv[1] = file;
        argv[2] = null;
        Pid pid = fork();
        if(pid == 0) {
                execv("/bin/nano", argv);
        }
        pid.wait(null, 0);
}

fn void showLine(int x) {
        for(int i = 0; i < tb::height(); i++) tb::writeC(x, i, ' ', tb::DEFAULT, tb::MAGENTA);
}

fn void showFile(int start, int cursor) {
        ZString currentPath = posix::getcwd(null, 0);
        defer libc::free((void*)currentPath);
        posix::DIRPtr cur = posix::opendir(currentPath);
        defer posix::closedir(cur);
        Posix_dirent* entry = getEntry((usz)cursor + start, cur);
        if(entry.d_type != posix::DT_REG) return;
        File f = file::open(((ZString)&entry.name).str_view(), "r")!!;
        defer f.close()!!;
        int x = tb::width() / 2 + 1;
        int y = 0;
        while(!f.eof()) {
                char! c = f.read_byte();
                if(catch c) break;
                if(c == '\n') {
                        y++;
                        x = tb::width() / 2 + 1;
                } else {
                        tb::writeC(x, y, c, tb::DEFAULT, tb::DEFAULT);
                }
                x++;
        }
}

macro int min(int a, int b) {
        return a < b ? a : b;
}

fn void main() {
        Event e;
        int pos = 0;
        bool cont = true;
        int entryN = fileCount();
        int start = 0;
        tb::init();
        while(cont) {
                switch(e.peek(10)) { 
                        case tb::EventType.KEY.code: {
                                switch(e.key) {
                                        case tb::Key.ESC.code: menu(&cont);
                                        case tb::Key.ARROW_UP.code: {
                                                if(pos == 0 && start > 0) {
                                                        start--;
                                                } else {
                                                        pos--;
                                                }
                                        }
                                        case tb::Key.ARROW_DOWN.code: {
                                                if(pos == tb::height() - 1 && start + tb::height() < entryN) {
                                                        start++;
                                                } else {
                                                        pos++;
                                                }
                                        }
                                        case tb::Key.ENTER.code: {
                                                ZString currentPath = posix::getcwd(null, 0);
                                                defer libc::free((void*)currentPath);
                                                posix::DIRPtr cur = posix::opendir(currentPath);
                                                defer posix::closedir(cur);
                                                Posix_dirent* entry = getEntry((usz)pos + start, cur);
                                                if(entry.d_type == posix::DT_DIR) {
                                                        posix::chdir((ZString)&entry.name);
                                                        entryN = fileCount();
                                                } else if(entry.d_type == posix::DT_REG) {
//                                                         openFile(&entry.name);
                                                }
                                        }
                                }
                                break;
                        }
                        default: break;
                }
                if(pos >= tb::height() && start + tb::height() >= entryN) {
                        pos = 0;
                        start = 0;
                }
                if(pos < 0) {
                        pos = min(tb::height(), entryN) - 1;
                        if(entryN > tb::height()) start = entryN - tb::height();
                }
                tb::clear();
                printCurrentDir(pos, -start);
                showLine(tb::width() / 2);
//                 showFile(start, pos);
                tb::present();
        }
        tb::shutdown();
}
