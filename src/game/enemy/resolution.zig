// #region Namespace imports
const std = @import("std");
const engine = @import("../../engine/engine.zig");
// #endregion

// #region Concrete imports
const GameWorld = @import("../world/world.zig").GameWorld;
const NPCActionPlan = @import("../enemy/action_plan.zig").NPCActionPlan;
const Enemy = @import("../enemy/enemy.zig").Enemy;
// #endregion

pub fn resolve(world: *GameWorld) void {
    const enemies = world.enemies.items;
    for(0..enemies.len) |index| {
        var enemy= &enemies[index];
        //std.debug.print("Resolving enemy {d}\n",.{enemy.entityId});
        if(enemy.action_plan != null){
            resolveNPCPlan(enemy,  world);
        }
        if (enemy.health.isDead()) {
            std.debug.print("Enemy {d} is dead\n",.{enemy.entityId});
            world.destroyEnemy(enemy.entityId);
        } 
    }
}

fn resolveNPCPlan(enemy:*Enemy, world: *GameWorld) void { 
    const plan = &enemy.action_plan.?;

    switch(plan.action){
        .ChangeState => {
            enemy.state = plan.newState.?;
            enemy.action_plan=null;
            //std.debug.print("Enemy {d} state changed and is now {d}\n",.{enemy.entityId,enemy.state});
            return;
        },
        .ApplyState => {}
    }
    //std.debug.print("Enemy {d} state is {any}\n",.{enemy.entityId,enemy.state});
    switch(enemy.state){
        .Idle => {},
        .Wandering => resolveWanderingPlan(enemy, plan, world),
        .Chasing => resolveChasingPlan(enemy, plan, world),
        //.Guarding => resolveGuardingPlan(enemy, &plan, world),
        //.Fleeing => resolveFleeingPlan(enemy, &plan, world),
        else =>{},
    }
    enemy.action_plan = null;
}

fn resolveChasingPlan(enemy:*Enemy,plan:*const NPCActionPlan,world:*GameWorld) void {
    if (plan.target==null) return;
    if (engine.frames_counter % 20 != 0) return;
    const target = plan.target.?;
    const isAvailable= !world.isCellOccupied(target);
    if (isAvailable) {
        //std.debug.print("Destination for {d} : ({d},{d})\n",.{enemy.entityId, target.x,target.y});
        enemy.move(target);
        return;
    }   
    if (world.character==null){
        return;
    }
    const character= &world.character.?;
    if (!target.equal(&character.position.cell)) {
        return;
    }
    character.health.takeDamage(enemy.force);
}

fn resolveWanderingPlan(enemy:*Enemy,plan:*const NPCActionPlan,world:*GameWorld) void {
    if (plan.target==null) return;
    if (engine.frames_counter % 20 != 0) return;
    const target = plan.target.?;
    const isAvailable= !world.isCellOccupied(target);
    if (isAvailable) {
        //std.debug.print("Destination for {d} : ({d},{d})\n",.{enemy.entityId, target.x,target.y});
        enemy.move(target);
    }   
}

//fn resolveFleeingPlan(_enemy:*Enemy,_plan:*NPCActionPlan,_index:usize,_world:*GameWorld) void {
//   if (engine.frames_counter % 20 != 0) return;
//    return;
//}

//fn resolveGuardingPlan(_enemy:*Enemy,_plan:*NPCActionPlan,_index:usize,_world:*GameWorld) void {
 //   if (engine.frames_counter % 20 != 0) return;
//    return;
//}


pub fn clearPlans(world: *GameWorld) void {
    for (world.enemies.items) |*enemy| enemy.action_plan = null;
}
