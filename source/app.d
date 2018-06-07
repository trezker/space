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
	bool accelerate;
	bool rotate_left;
	bool rotate_right;
};

struct View {
	vec2 displaysize;
	vec2 center;
};

void initialize_allegro() {
		if(!al_init()) {
			throw new StringException("Failed to initialize allegro");
		}
		
		al_install_keyboard();
		al_install_mouse();
		al_init_image_addon();
		al_init_font_addon();
		al_init_ttf_addon();
		al_init_primitives_addon();
}

ALLEGRO_DISPLAY* create_display()  {
	al_set_new_display_flags(ALLEGRO_WINDOWED | ALLEGRO_OPENGL);
	al_set_new_display_option(ALLEGRO_DISPLAY_OPTIONS.ALLEGRO_DEPTH_SIZE, 24, ALLEGRO_REQUIRE);
	ALLEGRO_DISPLAY* display = al_create_display(1280, 1024);
	if(!display) {
		throw new StringException("Failed to create display");
	}
	return display;
}

ALLEGRO_EVENT_QUEUE* initialize_event_queue(ALLEGRO_DISPLAY* display, ALLEGRO_TIMER* timer) {
	ALLEGRO_EVENT_QUEUE* queue = al_create_event_queue();
	al_register_event_source(queue, al_get_display_event_source(display));
	al_register_event_source(queue, al_get_keyboard_event_source());
	al_register_event_source(queue, al_get_mouse_event_source());
	al_register_event_source(queue, al_get_timer_event_source(timer));
	return queue;
}

void ship_events(ref Ship ship, ALLEGRO_EVENT event) {
	switch(event.type)
	{
		case ALLEGRO_EVENT_KEY_DOWN:
		{
			switch(event.keyboard.keycode)
			{
				case ALLEGRO_KEY_UP:
				{
					ship.accelerate = true;
					break;
				}
				case ALLEGRO_KEY_LEFT:
				{
					ship.rotate_left = true;
					break;
				}
				case ALLEGRO_KEY_RIGHT:
				{
					ship.rotate_right = true;
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
					ship.accelerate = false;
					break;
				}
				case ALLEGRO_KEY_LEFT:
				{
					ship.rotate_left = false;
					break;
				}
				case ALLEGRO_KEY_RIGHT:
				{
					ship.rotate_right = false;
					break;
				}
				default:
			}
			break;
		}
		default:
	}
}

int main(char[][] args) {
	return al_run_allegro({
		initialize_allegro();
		ALLEGRO_DISPLAY* display = create_display();

		float timer_interval = 0.02;
		ALLEGRO_TIMER *timer = al_create_timer(timer_interval);
		al_start_timer(timer);

		ALLEGRO_EVENT_QUEUE* queue = initialize_event_queue(display, timer);
		ALLEGRO_FONT* font = al_load_font("DejaVuSans.ttf", 18, 0);

		View mainview = {
			displaysize: [1280f, 1024f],
			center: [0f,0f]
		};

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
			color: ALLEGRO_COLOR(1, 1, 1, 1),
			accelerate: false,
			rotate_left: false,
			rotate_right: false
		};

		ship.position.x = (planet.radius + ship.radius) * cos(ship.rotation);
		ship.position.y = (planet.radius + ship.radius) * sin(ship.rotation);

		bool exit = false;
		while(!exit)
		{
			ALLEGRO_EVENT event;
			while(al_get_next_event(queue, &event))
			{
				ship_events(ship, event);

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
							default:
						}
						break;
					}
					case ALLEGRO_EVENT_TIMER:
					{
						if(ship.rotate_left) {
							ship.rotation -= PI * timer_interval;
							if(ship.rotation < -PI) {
								ship.rotation += PI*2;
							}
						}
						if(ship.rotate_right) {
							ship.rotation += PI * timer_interval;
							if(ship.rotation > PI) {
								ship.rotation -= PI*2;
							}
						}
						if(ship.accelerate) {
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

						mainview.center = ship.position;

						break;
					}
					default:
				}
			}

			al_clear_to_color(ALLEGRO_COLOR(0, 0, 0, 1));


			draw_planet(planet, mainview);
			draw_ship(ship, mainview);

			al_draw_text(font, ALLEGRO_COLOR(1, 1, 1, 1), 10, 10, ALLEGRO_ALIGN_LEFT, "Hello!");
			al_draw_text(font, ALLEGRO_COLOR(1, 1, 1, 1), 10, 30, ALLEGRO_ALIGN_LEFT, toStringz(to!string(ship.rotation)));
			al_flip_display();
		}

		return 0;
	});
}

void draw_planet(Planet planet, View view) {
	al_draw_circle(view.displaysize.x/2-view.center.x, view.displaysize.y/2-view.center.y, planet.radius, planet.color, 1);
}

void draw_ship(Ship ship, View view) {
	float x = -view.center.x + view.displaysize.x/2 + ship.position.x;
	float y = -view.center.y + view.displaysize.y/2 + ship.position.y;

	float p1x = x + ship.radius * cos(ship.rotation);
	float p1y = y + ship.radius * sin(ship.rotation);

	float p2x = x + ship.radius * cos(ship.rotation + PI * 0.75);
	float p2y = y + ship.radius * sin(ship.rotation + PI * 0.75);

	float p3x = x + ship.radius * cos(ship.rotation - PI * 0.75);
	float p3y = y + ship.radius * sin(ship.rotation - PI * 0.75);

	al_draw_triangle(p1x, p1y, p2x, p2y, p3x, p3y, ship.color, 1);
}