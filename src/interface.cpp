#include "interface.hpp"

Interface& Interface::instance() {
    static Interface interface;
    return interface;
}

Interface::Interface() {

}

Interface::~Interface() {

}
