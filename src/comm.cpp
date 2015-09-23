#include "r2d2_base.h"
#include "comm.h"

#include <iostream>

namespace r2d2 {
bool Comm::open() {
    return this->transport_->open();
}

void Comm::sendMessage(Message &msg, uint8_t * re_buf, size_t re_buf_size) {
    std::string out = msg.get_value();

    this->transport_->devWrite(msg.requiresResponse(), reinterpret_cast<uint8_t *>(const_cast<char *>(out.c_str())), static_cast<int>(out.size()), re_buf, static_cast<int>(re_buf_size));
}
}
