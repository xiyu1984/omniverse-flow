pub fun main() {
    let my_name = "63ceC801223fBA7Eb387193a6aEa1965Df8F439B";

    log(my_name.utf8);
    log(my_name.decodeHex());

    log(String.encodeHex([99, 206, 200, 1, 34, 63, 186, 126, 179, 135, 25, 58, 106, 234, 25, 101, 223, 143, 67, 155]));
}