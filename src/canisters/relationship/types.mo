import Time "mo:base/Time";

module Types {

    public type Message = {
        sender : Principal;
        content : Text;
        time : Time.Time;
    };

};
