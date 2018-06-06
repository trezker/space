import std.stdio;
import std.conv;
import std.math;
import std.string;
import gl3n.linalg;

import allegro5.allegro;
import allegro5.allegro_primitives;
import allegro5.allegro_image;
import allegro5.allegro_font;
import allegro5.allegro_ttf;
import allegro5.allegro_color;

struct Planet {
	float radius;
	float mass;
	float orbit;
	ALLEGRO_COLOR color;
};

struct Ship {
	float radius;
	float rotation;
	vec2 position;
	vec2 velocity;
	ALLEGRO_COLOR color;
};

int main(char[][] args) {
	return al_run_allegro({
		if(!al_init()) {
			writeln("Failed to init");
			return 0;
		}
		
		al_install_keyboard();
		al_install_mouse();
		al_init_image_addon();
		al_init_font_addon();
		al_init_ttf_addon();
		al_init_primitives_addon();

		al_set_new_display_flags(ALLEGRO_WINDOWED | ALLEGRO_OPENGL);
		al_set_new_display_option(ALLEGRO_DISPLAY_OPTIONS.ALLEGRO_DEPTH_SIZE, 24, ALLEGRO_REQUIRE);
		ALLEGRO_DISPLAY* display = al_create_display(1280, 1024);
		if(!display) {
			writeln("Failed to create display");
			return 0;
		}

		float timer_interval = 0.02;
		ALLEGRO_TIMER *timer = al_create_timer(timer_interval);
		al_start_timer(timer);

		ALLEGRO_EVENT_QUEUE* queue = al_create_event_queue();

		al_register_event_source(queue, al_get_display_event_source(display));
		al_register_event_source(queue, al_get_keyboard_event_source());
		al_register_event_source(queue, al_get_mouse_event_source());
		al_register_event_source(queue, al_get_timer_event_source(timer));

		ALLEGRO_FONT* font = al_load_font("DejaVuSans.ttf", 18, 0);

		int halfdisplaywidth = 1280/2;
		int halfdisplayheight = 1024/2;

		Planet planet = {
			radius: 100,
			mass: 50000,
			orbit: 0,
			color: ALLEGRO_COLOR(0, 1, 0, 1)
		};

		Ship ship = {
			radius: 10,
			rotation: PI,
			position: [0.0f, 0.0f],
			velocity: [0.0f, 0.0f],
			color: ALLEGRO_COLOR(1, 1, 1, 1)
		};

		ship.position.x = (planet.radius + ship.radius) * cos(ship.rotation);
		ship.position.y = (planet.radius + ship.radius) * sin(ship.rotation);

		bool accelerate = false;
		bool rotate_left = false;
		bool rotate_right = false;

		bool exit = false;
		while(!exit)
		{
			ALLEGRO_EVENT event;
			while(al_get_next_event(queue, &event))
			{
				switch(event.type)
				{
					case ALLEGRO_EVENT_DISPLAY_CLOSE:
					{
						exit = true;
						break;
					}
					case ALLEGRO_EVENT_KEY_DOWN:
					{
						switch(event.keyboard.keycode)
						{
							case ALLEGRO_KEY_ESCAPE:
							{
								exit = true;
								break;
							}
							case ALLEGRO_KEY_UP:
							{
								accelerate = true;
								break;
							}
							case ALLEGRO_KEY_LEFT:
							{
								rotate_left = true;
								break;
							}
							case ALLEGRO_KEY_RIGHT:
							{
								rotate_right = true;
								break;
							}
							default:
						}
						break;
					}
					case ALLEGRO_EVENT_KEY_UP:
					{
						switch(event.keyboard.keycode)
						{
							case ALLEGRO_KEY_UP:
							{
								accelerate = false;
								break;
							}
							case ALLEGRO_KEY_LEFT:
							{
								rotate_left = false;
								break;
							}
							case ALLEGRO_KEY_RIGHT:
							{
								rotate_right = false;
								break;
							}
							default:
						}
						break;
					}
					case ALLEGRO_EVENT_MOUSE_BUTTON_DOWN:
					{
						exit = true;
						break;
					}
					case ALLEGRO_EVENT_TIMER:
					{
						if(rotate_left) {
							ship.rotation -= PI * timer_interval;
							if(ship.rotation < -PI) {
								ship.rotation += PI*2;
							}
						}
						if(rotate_right) {
							ship.rotation += PI * timer_interval;
							if(ship.rotation > PI) {
								ship.rotation -= PI*2;
							}
						}
						if(accelerate) {
							vec2 direction = [cos(ship.rotation), sin(ship.rotation)];
							ship.velocity += 500 * direction * timer_interval;
						}

						vec2 planet_position = [0f, 0f];
						vec2 difference = planet_position - ship.position;

						float force = planet.mass / difference.magnitude_squared;
						ship.velocity += difference.normalized() * force;
						ship.position += ship.velocity * timer_interval;

						difference = ship.position - planet_position;
						if(difference.length < planet.radius + ship.radius) {
							ship.position = planet_position + difference.normalized() * (planet.radius + ship.radius);
							ship.velocity = vec2([0f, 0f]);

							float a = atan2(difference.y, difference.x);
							float phi = fmod(abs(ship.rotation - a), PI*2);
							float angledifference = phi > PI ? PI*2 - phi : phi;
							if(angledifference < PI/4) {
								ship.rotation = a;
							}
						}

						break;
					}
					default:
				}
			}

			al_clear_to_color(ALLEGRO_COLOR(0, 0, 0, 1));

			al_draw_circle(halfdisplaywidth, halfdisplayheight, planet.radius, planet.color, 1);

			float x = halfdisplaywidth + ship.position.x;
			float y = halfdisplayheight + ship.position.y;

			float p1x = x + ship.radius * cos(ship.rotation);
			float p1y = y + ship.radius * sin(ship.rotation);

			float p2x = x + ship.radius * cos(ship.rotation + PI * 0.75);
			float p2y = y + ship.radius * sin(ship.rotation + PI * 0.75);

			float p3x = x + ship.radius * cos(ship.rotation - PI * 0.75);
			float p3y = y + ship.radius * sin(ship.rotation - PI * 0.75);

			al_draw_triangle(p1x, p1y, p2x, p2y, p3x, p3y, ship.color, 1);
			al_draw_text(font, ALLEGRO_COLOR(1, 1, 1, 1), 10, 10, ALLEGRO_ALIGN_LEFT, "Hello!");
			al_draw_text(font, ALLEGRO_COLOR(1, 1, 1, 1), 10, 30, ALLEGRO_ALIGN_LEFT, toStringz(to!string(ship.rotation)));
			al_flip_display();
		}

		return 0;
	});
}