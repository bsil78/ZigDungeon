pub const Health = struct {
    hp: u16,
    max_hp: u16,

    pub fn isDead(self: Health) bool {
        return self.hp == 0;
    }

    pub fn takeDamage(self: *Health, amount: u16) void {
        if (self.hp > amount) {
            self.hp -= amount;
        } else {
            self.hp = 0;
        }
    }

    pub fn heal(self: *Health, amount: u16) void {
        if (self.hp + amount > self.max_hp) {
            self.hp = self.max_hp;
        } else {
            self.hp += amount;
        }
    }
};
