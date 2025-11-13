/*
 * QUEST ADVENTURE GAME - C Implementation
 * Converted from QuickBASIC
 * A text-based adventure game with rooms, artifacts, and creatures
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <ctype.h>

#define MAX_ARTIFACTS 60
#define MAX_GREMLINS 40
#define MAX_LOCATIONS 5
#define RECORD_SIZE 100
#define MAX_OUTPUT 1024

/* Game record structure */
typedef struct {
    char data_record[RECORD_SIZE + 1];
} GameRecord;

/* Global variables */
FILE *game_file = NULL;
GameRecord game_rec;
int record_number;

/* Parsed command variables */
int new_place;
int parsed_number;
char processed_word[50];
char command_args[10];
char parsed_text1[100];
char parsed_text2[100];
char text_continue[5];
char user_input[200];
char user_filename[100];
char user_response[10];
char gremlin_data[RECORD_SIZE + 1];
int target_gremlin;
int found_target;
int gremlin_index;
int artifact_index;
int index_var;
int check_index;
int action_index;
int process_index;
int optimal_move;

/* Game state variables */
int current_room;
int home_room;
int warehouse_room;
int dark_room;
int move_count;
int carry_count;
int player_state;
double score;
int penalty_points;
int random_seed;

/* Game arrays */
int artifact_location[MAX_ARTIFACTS + 1];
int artifact_record[MAX_ARTIFACTS + 1];
int gremlin_location[MAX_GREMLINS + 1];
int gremlin_record[MAX_GREMLINS + 1];
int gremlin_factor[MAX_GREMLINS + 1];
int location_list[MAX_LOCATIONS + 1];
int recent_places[MAX_LOCATIONS + 1];

/* Game control variables */
int num_artifacts;
int num_gremlins;
int current_record;
int flag_record;
char action_result;
char secondary_action[10];
char record_content[RECORD_SIZE + 1];
char place_record[RECORD_SIZE + 1];

/* Text processing variables */
char word1[10];
char word2[10];
char cur_command[10];
char action[10];
char output_buffer[MAX_OUTPUT];
char text_output[MAX_OUTPUT];

/* Function declarations */
void arrive_at_location(void);
void calculate_score(void);
void check_additional_conditions(void);
void check_artifact_commands(void);
void check_gremlin_attacks(void);
void check_keyword_interactions(void);
void check_movement_commands(void);
void check_player_state(void);
void check_standard_commands(void);
void check_target_eligibility(int idx);
void convert_to_uppercase(char *word_string);
void destroy_object(void);
void display_message(void);
void execute_action(void);
void execute_carry_action(void);
void execute_complex_action(void);
void execute_destroy_action(void);
void execute_drop_action(void);
void execute_message_action(void);
void execute_move_action(void);
void execute_player_action(void);
void execute_state_action(void);
void extract_word(char **input_string);
void find_action_in_record(void);
void flush_output(void);
void get_player_input(void);
void get_record(void);
void handle_artifact_action(int artifact_idx);
void handle_attack_command(void);
void handle_carry_artifact(int artifact_idx);
void handle_creature_interaction(void);
void handle_debug_command(void);
void handle_drop_artifact(int artifact_idx);
void handle_end_command(void);
void handle_feed_command(void);
void handle_inventory_command(void);
void handle_kill_command(void);
void handle_look_command(void);
void handle_movement(void);
void handle_player_command(void);
void handle_player_death(void);
void handle_player_movement(void);
void handle_player_state_change(void);
void handle_player_state_toggle(void);
void handle_score_command(void);
void handle_specific_artifact(int artifact_idx);
void handle_throw_artifact(int artifact_idx);
void handle_use_artifact(int artifact_idx);
void initialize_game(void);
void load_artifacts(void);
void load_game(void);
void load_game_data(void);
void load_gremlins(void);
void parse_command(char *input_string);
void parse_item_number(char *item_string);
void parse_text_tokens(void);
void place_artifact(int artifact_idx);
void process_all_targets(char *operation_type);
void process_artifact_description(void);
void process_artifacts_at_location(void);
void process_both_conditions(void);
void process_command(void);
void process_complex_movement(void);
void process_conditional_movement(void);
void process_description(void);
void process_destroy(void);
void process_dynamic_message(void);
void process_failed_condition(void);
void process_feed_kill_command(void);
void process_gremlin_action(int g_index);
void process_gremlins(void);
void process_gremlins_at_location(void);
void process_location_change(void);
void process_location_description(void);
void process_mandatory_items(void);
void process_movement(void);
void process_object_interaction(void);
void process_object_message(void);
void process_random_target(char *operation_type);
void process_specific_target(int target_idx, char *operation_type);
void process_state_change(void);
void process_successful_condition(void);
void process_successful_feed_kill(int item_idx, int message_number);
void process_target_action(void);
void process_text_output(void);
void save_game(void);
void save_record(void);
void start_game_loop(void);
void validate_game_state(void);
void wrap_text(void);

/* Utility function to get substring */
void mid_str(char *dest, const char *src, int start, int len) {
    int src_len = strlen(src);
    if (start > src_len) {
        dest[0] = '\0';
        return;
    }
    int copy_len = (start + len > src_len) ? src_len - start : len;
    strncpy(dest, src + start, copy_len);
    dest[copy_len] = '\0';
}

/* Utility function to get left substring */
void left_str(char *dest, const char *src, int len) {
    int src_len = strlen(src);
    int copy_len = (len > src_len) ? src_len : len;
    strncpy(dest, src, copy_len);
    dest[copy_len] = '\0';
}

/* Utility function to get right substring */
void right_str(char *dest, const char *src, int len) {
    int src_len = strlen(src);
    if (len >= src_len) {
        strcpy(dest, src);
        return;
    }
    strcpy(dest, src + src_len - len);
}

/* Initialize game */
void initialize_game(void) {
    game_file = fopen("QDATA.dat", "rb+");
    if (!game_file) {
        printf("Error: Cannot open QDATA.dat\n");
        exit(1);
    }
    random_seed = 1;
    carry_count = 0;
    strcpy(secondary_action, "0");
    move_count = 100;
    penalty_points = 0;
    action_result =  'N';
    output_buffer[0] = '\0';
}

/* Get record from file */
void get_record(void) {
    record_number = current_record + 1;
    if (record_number < 0) record_number = 0;
    
    fseek(game_file, (long)(record_number - 1) * RECORD_SIZE, SEEK_SET);
    fread(&game_rec.data_record, RECORD_SIZE, 1, game_file);
    game_rec.data_record[RECORD_SIZE] = '\0';
    strcpy(record_content, game_rec.data_record);
    printf("%s\n", record_content);
}

/* Save record to file */
void save_record(void) {
    strcpy(game_rec.data_record, record_content);
    fseek(game_file, (long)current_record * RECORD_SIZE, SEEK_SET);
    fwrite(&game_rec.data_record, RECORD_SIZE, 1, game_file);
    fflush(game_file);
}

/* Load game data */
void load_game_data(void) {
    char temp[10];
    current_record = 0;
    get_record();
    
    mid_str(temp, record_content, 20, 4);
    current_room = atoi(temp);
    mid_str(temp, record_content, 24, 4);
    home_room = atoi(temp);
    mid_str(temp, record_content, 28, 4);
    warehouse_room = atoi(temp);
    mid_str(temp, record_content, 32, 4);
    dark_room = atoi(temp);
    mid_str(temp, record_content, 10, 4);
    current_record = atoi(temp);
    mid_str(temp, record_content, 16, 4);
    flag_record = atoi(temp);
    mid_str(temp, record_content, 8, 2);
    num_artifacts = atoi(temp);
    mid_str(temp, record_content, 14, 2);
    num_gremlins = atoi(temp);
    
    load_artifacts();
    load_gremlins();
}

/* Load artifacts */
void load_artifacts(void) {
    char temp[10];
    current_record = flag_record;
    do {
        get_record();
        mid_str(temp, record_content, 90, 2);
        int idx_a = atoi(temp);
        if (idx_a >= 1 && idx_a <= MAX_ARTIFACTS) {
            mid_str(temp, record_content, 92, 4);
            artifact_location[idx_a] = atoi(temp);
            artifact_record[idx_a] = current_record;
        }
        left_str(temp, record_content, 4);
        current_record = atoi(temp);
    } while (current_record > 0);
}

/* Load gremlins */
void load_gremlins(void) {
    char temp[10];
    current_record = flag_record;
    do {
        get_record();
        mid_str(temp, record_content, 90, 2);
        int idx_g = atoi(temp);
        if (idx_g >= 1 && idx_g <= MAX_GREMLINS) {
            mid_str(temp, record_content, 92, 4);
            gremlin_location[idx_g] = atoi(temp);
            gremlin_record[idx_g] = current_record;
            mid_str(temp, record_content, 80, 1);
            gremlin_factor[idx_g] = atoi(temp);
        }
        left_str(temp, record_content, 4);
        current_record = atoi(temp);
    } while (current_record > 0);
}

/* Extract word from input string */
void extract_word(char **input_string) {
    char *str = *input_string;
    
    /* Skip leading spaces */
    while (*str == ' ') str++;
    
    /* Find next space */
    char *space_pos = strchr(str, ' ');
    int word_len;
    
    if (space_pos == NULL) {
        word_len = strlen(str);
    } else {
        word_len = space_pos - str;
    }
    
    if (word_len > 0) {
        strncpy(processed_word, str, word_len);
        processed_word[word_len] = '\0';
    } else {
        processed_word[0] = '\0';
    }
    
    /* Move pointer past the word */
    if (space_pos != NULL) {
        *input_string = space_pos + 1;
    } else {
        *input_string = str + strlen(str);
    }
}

/* Convert to uppercase */
void convert_to_uppercase(char *word_string) {
    for (int i = 0; i < 4 && word_string[i] != '\0'; i++) {
        if (word_string[i] > '@') {
            word_string[i] = toupper(word_string[i]);
        }
    }
}

/* Parse command */
void parse_command(char *input_string) {
    char *input_ptr = input_string;
    
    extract_word(&input_ptr);
    strcpy(word1, processed_word);
    
    if (strlen(word1) == 0) {
        strcpy(word1, "*   ");
    } else {
        strcat(word1, "   ");
        word1[4] = '\0';
    }
    
    extract_word(&input_ptr);
    strcpy(word2, processed_word);
    
    if (strlen(word2) == 0) {
        strcpy(word2, "*   ");
    } else {
        strcat(word2, "   ");
        word2[4] = '\0';
    }
    
    convert_to_uppercase(word1);
    convert_to_uppercase(word2);
    
    if (strcmp(word1, "SAVE") == 0 && strcmp(word2, "*   ") == 0) {
        save_game();
        return;
    }
    if (strcmp(word1, "LOAD") == 0 && strcmp(word2, "*   ") == 0) {
        load_game();
        return;
    }
    if (strcmp(word1, "ZPQR") == 0) {
        handle_debug_command();
        return;
    }
}

/* Flush output buffer */
void flush_output(void) {
    if (strlen(output_buffer) > 0) {
        wrap_text();
    }
    if (strlen(output_buffer) > 0) {
        printf("%s\n", output_buffer);
        output_buffer[0] = '\0';
    }
}

/* Calculate score */
void calculate_score(void) {
    char temp[10];
    score = 0;
    
    for (artifact_index = 1; artifact_index <= num_artifacts; artifact_index++) {
        if (artifact_location[artifact_index] == home_room) {
            current_record = artifact_record[artifact_index];
            get_record();
            mid_str(temp, record_content, 8, 1);
            int state_value = atoi(temp);
            mid_str(temp, record_content, 80 + state_value * 2, 1);
            if (strcmp(temp, "2") == 0) {
                mid_str(temp, record_content, 78, 3);
                score += atoi(temp);
            }
        }
    }
    
    if (move_count == 0) move_count = 1;
    score = ((int)(1000.0 * (10.0 * score - penalty_points) / move_count)) / 100.0;
}

/* Display message */
void display_message(void) {
    if (current_record == 0) return;
    
    get_record();
    parse_text_tokens();
    
    strcpy(text_output, parsed_text1);
    process_text_output();
    
    if (strcmp(text_continue, "1") == 0) return;
    
    strcpy(text_output, parsed_text2);
    process_text_output();
    
    if (strcmp(text_continue, "3") == 0) {
        current_record++;
        display_message();
    }
}

/* Parse text tokens (simplified) */
void parse_text_tokens(void) {
    left_str(parsed_text1, record_content, 40);
    mid_str(parsed_text2, record_content, 40, 40);
    
    char temp[5];
    right_str(temp, record_content, 1);
    if (strcmp(temp, "3") == 0) {
        strcpy(text_continue, "3");
    } else {
        strcpy(text_continue, "1");
    }
}

/* Process text output */
void process_text_output(void) {
    if (strlen(text_output) == 0) return;
    
    if (text_output[strlen(text_output) - 1] == '.') {
        strcat(text_output, " ");
    }
    
    strcat(output_buffer, text_output);
    strcat(output_buffer, " ");
    
    if (strlen(output_buffer) > 70) {
        wrap_text();
    }
}

/* Wrap text */
void wrap_text(void) {
    char *wrap_pos = strrchr(output_buffer, ' ');
    if (wrap_pos != NULL && (wrap_pos - output_buffer) > 60) {
        *wrap_pos = '\0';
        printf("%s\n", output_buffer);
        strcpy(output_buffer, wrap_pos + 1);
    }
}

/* Save game */
void save_game(void) {
    printf("FILE NAME PLEASE  :");
    scanf("%s", user_filename);
    
    FILE *save_file = fopen(user_filename, "w");
    if (!save_file) {
        printf("Error saving game\n");
        return;
    }
    
    fprintf(save_file, "%d %lf %d %d %d %d\n", 
            current_room, score, move_count, penalty_points, carry_count, random_seed);
    
    for (index_var = 1; index_var <= MAX_ARTIFACTS; index_var++) {
        fprintf(save_file, "%d %d\n", artifact_location[index_var], artifact_record[index_var]);
    }
    
    for (index_var = 1; index_var <= MAX_GREMLINS; index_var++) {
        fprintf(save_file, "%d %d %d\n", 
                gremlin_location[index_var], gremlin_record[index_var], gremlin_factor[index_var]);
    }
    
    for (index_var = 1; index_var <= MAX_LOCATIONS; index_var++) {
        fprintf(save_file, "%d %d\n", location_list[index_var], recent_places[index_var]);
    }
    
    fclose(save_file);
    arrive_at_location();
}

/* Load game */
void load_game(void) {
    printf("FILE NAME PLEASE  :");
    scanf("%s", user_filename);
    
    FILE *load_file = fopen(user_filename, "r");
    if (!load_file) {
        printf("Error loading game\n");
        return;
    }
    
    fscanf(load_file, "%d %lf %d %d %d %d", 
           &current_room, &score, &move_count, &penalty_points, &carry_count, &random_seed);
    
    for (index_var = 1; index_var <= MAX_ARTIFACTS; index_var++) {
        fscanf(load_file, "%d %d", &artifact_location[index_var], &artifact_record[index_var]);
    }
    
    for (index_var = 1; index_var <= MAX_GREMLINS; index_var++) {
        fscanf(load_file, "%d %d %d", 
               &gremlin_location[index_var], &gremlin_record[index_var], &gremlin_factor[index_var]);
    }
    
    for (index_var = 1; index_var <= MAX_LOCATIONS; index_var++) {
        fscanf(load_file, "%d %d", &location_list[index_var], &recent_places[index_var]);
    }
    
    fclose(load_file);
    arrive_at_location();
}

/* Validate game state */
// validate_game_state()
// This function ensures the game state remains consistent by:
// 
// Checking all artifact locations are valid (>= -1)
// Checking all gremlin locations are valid (>= -1)
// Ensuring carry count stays within valid bounds (0 to num_artifacts)
void validate_game_state(void) {
    /* Ensure artifact locations are valid */
    for (artifact_index = 1; artifact_index <= num_artifacts; artifact_index++) {
        if (artifact_location[artifact_index] < -1) {
            artifact_location[artifact_index] = current_room;
        }
    }
    
    /* Ensure gremlin locations are valid */
    for (gremlin_index = 1; gremlin_index <= num_gremlins; gremlin_index++) {
        if (gremlin_location[gremlin_index] < -1) {
            gremlin_location[gremlin_index] = -1;
        }
    }
    
    /* Ensure carry count is valid */
    if (carry_count < 0) carry_count = 0;
    if (carry_count > num_artifacts) carry_count = num_artifacts;
}

/* Arrive at location */
// arrive_at_location()
// This is a more complex function that handles what happens when the player arrives at a new location:
// 
// Loads the current room's record data
// Updates the location history (shifts recent_places array left and adds current room)
// Displays the location description
// Retrieves the player's current state from the place record
// Loads and displays the state-specific description
// Processes artifacts present at the location
// Processes gremlins present at the location
void arrive_at_location(void) {
    char temp[10];
    
    current_record = current_room;
    get_record();
    strcpy(place_record, record_content);
    
    left_str(temp, place_record, 4);
    current_record = atoi(temp);
    
    /* Update location history: shift RecentPlaces left, append current */
    for (int i = 1; i <= 4; i++) {
        recent_places[i] = recent_places[i + 1];
    }
    recent_places[5] = current_room;
    
    process_location_description();
    
    /* Get player state */
    mid_str(temp, place_record, 8, 1);
    player_state = atoi(temp);
    
    /* Get state-specific record */
    mid_str(temp, place_record, 6 + 4 * player_state, 4);
    current_record = atoi(temp);
    process_location_description();
    
    process_artifacts_at_location();
    process_gremlins_at_location();
}


/* Process command */
// process_command()
// The main command dispatcher that:
// 
// Checks for movement commands first
// Then checks keyword interactions (location/gremlin-specific)
// Then checks standard commands (LOOK, INVENTORY, etc.)
// Shows error message (record 344) if no valid command found
void process_command(void) {
    strcpy(cur_command, "?");
    strcpy(action, "?");
    
    check_movement_commands();
    if (strcmp(cur_command, "?") != 0) {
        handle_movement();
        return;
    }
    
    check_keyword_interactions();
    if (strcmp(action, "?") != 0) {
        execute_action();
        return;
    }
    
    check_standard_commands();
    if (strcmp(action, "?") != 0) {
        execute_action();
        return;
    }
    
    current_record = 344;
    display_message();
}

/* Check movement commands */
// check_movement_commands()
// Parses movement directions by:
// 
// Checking against standard directions: NORTH, SOUTH, EAST, WEST, UP, DOWN
// Also checking custom directions from the current place record (positions 25-32)
// Creates a command code like "C01", "C02", etc. for each direction
void check_movement_commands(void) {
    char direction_string[50];
    char temp[10];
    
    strcpy(direction_string, "NORTSOUTEASTWESTUP  DOWN");
    mid_str(temp, place_record, 25, 8);
    strcat(direction_string, temp);
    
    for (int idx = 0; idx < 29; idx += 4) {
        char dir[5];
        mid_str(dir, direction_string, idx, 4);
        if (strcmp(word1, dir) == 0) {
            /* Calculate command code */
            sprintf(cur_command, "C%02d", (idx + 4) / 4);
            break;
        }
    }
}

/* Handle movement */
// handle_movement()
// Executes movement by:
// 
// Searching the place record for the movement command code
// Executing the associated action if found
// Showing "You can't go that way" message (record 343) if invalid
void handle_movement(void) {
    strcpy(action, "?");
    strcpy(record_content, place_record);
    find_action_in_record();
    
    if (strcmp(action, "?") != 0) {
        execute_action();
    } else {
        current_record = 343;
        display_message();
    }
}

/* Process gremlins */
// process_gremlins()
// Handles gremlin AI by:
// 
// Incrementing gremlin factors for gremlins in current room
// Using random chance based on gremlin factor to trigger action
// Calling process_gremlin_action() when a gremlin acts
void process_gremlins(void) {
    int target_gremlin_local = 0;
    
    for (gremlin_index = 1; gremlin_index <= num_gremlins; gremlin_index++) {
        if (gremlin_location[gremlin_index] == current_room) {
            gremlin_factor[gremlin_index]++;
            
            if ((rand() % 10) <= gremlin_factor[gremlin_index]) {
                target_gremlin_local = gremlin_index;
                gremlin_factor[gremlin_index] = 9;
                break;
            }
        }
    }
    
    if (target_gremlin_local == 0) return;
    
    process_gremlin_action(target_gremlin_local);
}

/* Process gremlin action */
// process_gremlin_action()
// Executes a specific gremlin's action:
// 
// Loads gremlin's record and state
// Gets success chance based on current state
// Randomly determines success/failure
// Calls appropriate condition handler
void process_gremlin_action(int g_index) {
    char temp[10];
    
    current_record = gremlin_record[g_index];
    get_record();
    
    mid_str(temp, record_content, 85, 1);
    gremlin_factor[g_index] = atoi(temp);
    
    mid_str(temp, record_content, 8, 1);
    int state_value = atoi(temp);
    
    mid_str(temp, record_content, 86, 4);
    current_record = atoi(temp);
    if (current_record == 0) return;
    
    mid_str(temp, record_content, 81 + 2 * state_value, 1);
    int success_chance = atoi(temp);
    
    get_record();
    action_result = 'Y';
    
    if ((rand() % 9) < success_chance) {
        process_successful_condition();
    } else {
        process_failed_condition();
    }
}

/* Check gremlin attacks */
// check_gremlin_attacks()
// Processes gremlins after player action:
// 
// Iterates through all gremlins in the current room
// Processes interactions for each
// Converts following gremlins (negative location) to current room
// 
// All functions maintain the original QuickBASIC logic and use C idioms
// like rand() % 10 for random numbers instead of QB's Rnd.
void check_gremlin_attacks(void) {
    optimal_move = 9999;
    
    for (gremlin_index = 1; gremlin_index <= num_gremlins; gremlin_index++) {
        if (gremlin_location[gremlin_index] == current_room) {
            current_record = gremlin_record[gremlin_index];
            process_object_interaction();
        }
        
        /* Handle gremlins that were following (negative location) */
        if (gremlin_location[gremlin_index] == -current_room) {
            gremlin_location[gremlin_index] = current_room;
        }
    }
}


/* Process artifacts at location */
// process_artifacts_at_location()
// Lists all artifacts either in the current room or being carried (location 0):
// 
// Iterates through all artifacts
// Calls process_object_interaction() for each relevant artifact
// Uses optimal_move to track previous descriptions for proper formatting
void process_artifacts_at_location(void) {
    optimal_move = 9999;
    
    for (artifact_index = 1; artifact_index <= num_artifacts; artifact_index++) {
        if (artifact_location[artifact_index] == current_room || 
            artifact_location[artifact_index] == 0) {

            current_record = artifact_record[artifact_index];
            process_object_interaction();
        }
    }
}

/* Process gremlins at location */
// process_gremlins_at_location()
// Lists all gremlins in the current room:
// 
// Simpler than artifacts (only checks current room, not inventory)
// Calls process_object_interaction() for each gremlin present
void process_gremlins_at_location(void) {
    for (gremlin_index = 1; gremlin_index <= num_gremlins; gremlin_index++) {
        if (gremlin_location[gremlin_index] == current_room) {
            current_record = gremlin_record[gremlin_index];
            process_object_interaction();
        }
    }
}

/* Process object interaction */
// process_object_interaction()
// Displays an object's (artifact or gremlin) name and description:
// 
// Gets the object's current state
// Retrieves the state-specific name record
// Formats output with "and a" for multiple objects
// Uses optimal_move to avoid repeating descriptions
void process_object_interaction(void) {
    char temp[10];
    
    get_record();
    
    /* Get state value */
    mid_str(temp, record_content, 8, 1);
    int state_value = atoi(temp);
    
    /* Get name record */
    mid_str(temp, record_content, 6 + 4 * state_value, 4);
    int name_record = atoi(temp);
    
    /* Get description record */
    mid_str(temp, record_content, 4, 4);
    current_record = atoi(temp);
    
    if (current_record == 0) {
        /* Display name directly */
        optimal_move = current_record;
        current_record = name_record;
        display_message();
        return;
    }
    
    if (current_record == optimal_move) {
        strcpy(text_output, "%4and a");
        process_text_output();
    } else {
        display_message();
    }
    
    optimal_move = current_record;
    current_record = name_record;
    display_message();
}

/* Check keyword interactions */
// `check_keyword_interactions()
// `Checks for special keyword-based actions:
// `
// `First checks the place record for keyword actions ("* KR" marker)
// `Then checks each gremlin in the room for keyword actions
// `Processes from highest to lowest gremlin index (matching QB logic)
void check_keyword_interactions(void) {
    char temp[10];
    
    /* Check place record for keyword interactions */
    mid_str(temp, place_record, 25, 4);
    if (strcmp(temp, "* KR") == 0) {
        mid_str(temp, place_record, 29, 4);
        current_record = atoi(temp);
        find_action_in_record();
        if (strcmp(action, "?") != 0) return;
    }
    
    /* Check gremlins' keywords */
    for (gremlin_index = num_gremlins; gremlin_index >= 1; gremlin_index--) {
        if (gremlin_location[gremlin_index] == current_room) {
            current_record = gremlin_record[gremlin_index];
            get_record();
            
            mid_str(temp, record_content, 25, 4);
            if (strcmp(temp, "* KR") == 0) {
                mid_str(temp, record_content, 29, 4);
                current_record = atoi(temp);
                find_action_in_record();
                if (strcmp(action, "?") != 0) return;
            }
        }
    }
}

/* Check standard commands */
// check_standard_commands()
// Handles the built-in game commands:
// 
// Matches against: LOOK, INVE(ntory), FEED, SCOR(e), END, ATTA(ck), KILL
// Dispatches to appropriate handler function
// Falls through to check_artifact_commands() if no match
void check_standard_commands(void) {
    int command_index_local = 0;
    
    /* Check against standard command list */
    const char *commands = "LOOKINVEFEEDSCOREND ATTAKILL";
    for (check_index = 0; check_index < 28; check_index += 4) {
        char cmd[5];
        mid_str(cmd, commands, check_index, 4);
        if (strcmp(cmd, word1) == 0) {
            command_index_local = (check_index + 4) / 4;
            break;
        }
    }
    
    switch (command_index_local) {
        case 1: handle_look_command(); break;
        case 2: handle_inventory_command(); break;
        case 3: handle_feed_command(); break;
        case 4: handle_score_command(); break;
        case 5: handle_end_command(); break;
        case 6: handle_attack_command(); break;
        case 7: handle_kill_command(); break;
        default: check_artifact_commands(); break;
    }
}

/* Check artifact commands */
// check_artifact_commands()
// Handles artifact-specific commands:
// 
// Checks artifacts in room or inventory
// Looks for keyword records ("* KR")
// Checks for direct word matches (artifact names)
// Falls back to dark room actions if no artifact matches`
void check_artifact_commands(void) {
    char temp[10];
    int found = 0;
    
    for (artifact_index = 1; artifact_index <= num_artifacts; artifact_index++) {
        if (artifact_location[artifact_index] == current_room || 
            artifact_location[artifact_index] == 0) {
            
            current_record = artifact_record[artifact_index];
            get_record();
            
            /* Check for keyword record */
            mid_str(temp, record_content, 25, 4);
            if (strcmp(temp, "* KR") == 0) {
                mid_str(temp, record_content, 29, 4);
                current_record = atoi(temp);
                find_action_in_record();
                if (strcmp(action, "?") != 0) {
                    handle_artifact_action(artifact_index);
                    found = 1;
                    break;
                }
            }
            
            /* Check for direct word match */
            mid_str(temp, record_content, 25, 4);
            if (strcmp(temp, word2) == 0) {
                handle_specific_artifact(artifact_index);
                found = 1;
                break;
            }
            
            mid_str(temp, record_content, 29, 4);
            if (strcmp(temp, word2) == 0) {
                handle_specific_artifact(artifact_index);
                found = 1;
                break;
            }
        }
    }
    
    if (found == 0) {
        current_record = dark_room;
        find_action_in_record();
    }
}

// handle_look_command() - Displays the room's full description by loading the
// first record from the place record.
// handle_inventory_command() - Shows what the player is carrying:
// 
// Displays header message (record 342)
// Lists all artifacts with location 0 (carried)
// Shows "NOTHING" if inventory is empty
// 
// handle_feed_command() - Sets word1 to "F" and calls the creature interaction handler
// handle_attack_command() - Sets word1 to "A" and calls the creature interaction handler
// handle_kill_command() - Sets word1 to "K" and calls the creature interaction handler
// handle_creature_interaction() - Finds and interacts with a gremlin:
// 
// Searches for gremlin matching word2 in current room
// Checks both name fields (positions 25 and 29)
// Creates command code based on gremlin index
// Stores gremlin data and executes action
// 
// handle_score_command() - Displays current score
// handle_end_command() - Shows final score and exits game
// Action Execution:
// execute_action() - Main action dispatcher:
// 
// Determines action type from first digit (0-9)
// Routes to appropriate execution function
// Handles secondary actions (chained actions)


/* Handle look command */
void handle_look_command(void) {
    char temp[10];
    left_str(temp, place_record, 4);
    current_record = atoi(temp);
    display_message();
}

/* Handle inventory command */
void handle_inventory_command(void) {
    char temp[10];
    current_record = 342;
    display_message();
    
    char item_list[20] = "%1NOTHING%1";
    int any_item = 0;
    
    for (artifact_index = 1; artifact_index <= num_artifacts; artifact_index++) {
        if (artifact_location[artifact_index] == 0) {
            strcpy(text_output, "%1A ");
            process_text_output();
            current_record = artifact_record[artifact_index];
            get_record();
            process_description();
            strcpy(item_list, " %1");
            any_item = 1;
        }
    }
    
    if (any_item == 0) {
        strcpy(text_output, item_list);
        process_text_output();
    }
}

/* Handle feed command */
void handle_feed_command(void) {
    strcpy(word1, "F");
    handle_creature_interaction();
}

/* Handle attack command */
void handle_attack_command(void) {
    strcpy(word1, "A");
    handle_creature_interaction();
}

/* Handle kill command */
void handle_kill_command(void) {
    strcpy(word1, "K");
    handle_creature_interaction();
}

/* Handle creature interaction */
void handle_creature_interaction(void) {
    char temp[10];
    int target_gremlin_local = 1;
    int found = 0;
    
    while (target_gremlin_local <= num_gremlins) {
        if (gremlin_location[target_gremlin_local] != current_room) {
            target_gremlin_local++;
        } else {
            current_record = gremlin_record[target_gremlin_local];
            get_record();
            
            mid_str(temp, record_content, 25, 4);
            if (strcmp(temp, word2) == 0) {
                found = 1;
                break;
            }
            
            mid_str(temp, record_content, 29, 4);
            if (strcmp(temp, word2) == 0) {
                found = 1;
                break;
            }
            
            target_gremlin_local++;
        }
    }
    
    if (found == 0) {
        current_record = 339;
        display_message();
        return;
    }
    
    /* Create command code */
    sprintf(cur_command, "%c%02d", word1[0], (target_gremlin_local * 4) / 100);
    strcpy(gremlin_data, record_content);
    target_gremlin = target_gremlin_local;
    
    execute_action();
}

/* Handle score command */
void handle_score_command(void) {
    flush_output();
    printf("SCORE: %lf\n", score);
}

/* Handle end command */
void handle_end_command(void) {
    flush_output();
    printf("SCORE: %lf\n", score);
    if (game_file) fclose(game_file);
    exit(0);
}

/* Execute action */
void execute_action(void) {
    int action_type = atoi(action) + 1;
    
    switch (action_type) {
        case 1: return; /* No action */
        case 2: execute_message_action(); break;
        case 3: execute_move_action(); break;
        case 4: execute_complex_action(); break;
        case 5: execute_carry_action(); break;
        case 6: execute_drop_action(); break;
        case 7: execute_player_action(); break;
        case 8: execute_state_action(); break;
        case 9: execute_destroy_action(); break;
        case 10: execute_complex_action(); break;
    }
    
    if (strcmp(secondary_action, "0") != 0) {
        strcpy(action, secondary_action);
        strcpy(secondary_action, "0");
        execute_action();
    }
}

/* Execute message action */
// execute_message_action() - Displays a message:
// 
// Handles dynamic messages (with "??")
// Otherwise displays the specified record number
void execute_message_action(void) {
    char message_number[10];
    right_str(message_number, action, 4);
    
    if (strncmp(message_number, "??", 2) == 0) {
        process_dynamic_message();
    } else {
        current_record = atoi(message_number);
        display_message();
    }
}

/* Execute move action */
// execute_move_action() - Handles movement to new location:
// 
// Loads destination record
// Checks room type (last digit)
// Routes to: simple movement, complex movement, or conditional movement
void execute_move_action(void) {
    char temp[10];
    char place_str[10];
    
    right_str(place_str, action, 4);
    new_place = atoi(place_str);
    current_record = new_place;
    get_record();
    
    right_str(temp, record_content, 1);
    int room_type = atoi(temp);
    
    if (room_type < 6) {
        process_movement();
        return;
    }
    
    if (room_type > 6) {
        process_complex_movement();
        return;
    }
    
    process_conditional_movement();
}

// Conditional Movement Functions:
// process_conditional_movement() - Routes based on condition type (1-5)
// check_player_state() - Verifies player is in required state before allowing movement
// process_mandatory_items() - Checks required items (must carry) and forbidden items (must not carry/be present):
// 
// Uses positive numbers for artifacts that must be carried
// Uses negative numbers for gremlins that must/must not be present
// 
// check_additional_conditions() - Checks object states and random probability for success
// process_successful_condition() - Executes success action and message
// process_failed_condition() - Executes failure action and message
// process_both_conditions() - Executes both success action and secondary action
// Utility Functions:
// parse_item_number() - Parses item codes, handling "P" suffix for gremlin references (negative numbers)
// find_action_in_record() - Searches a record for matching command codes:
// 
// Handles exact matches
// Handles wildcard "??" matches for parametric commands
// 
// process_description() - Displays an object's state-specific description
// process_dynamic_message() - Handles dynamic messages with "??" placeholders
// process_artifact_description() - Gets the description record for an artifact's current state
// Artifact Handling Functions:
// handle_artifact_action() - Routes to CARRY, DROP, THROW, or USE
// handle_specific_artifact() - Handles direct artifact manipulation by name
// handle_carry_artifact() - Picks up artifact if possible (checks carry limit)
// handle_drop_artifact() - Drops artifact at current location
// handle_throw_artifact() - Drops and then triggers throw action (command "4")
// handle_use_artifact() - Uses artifact with verb (checks action words at positions 66-75)
// execute_carry_action() - Executes the carry action sequence
// execute_complex_action() - Handles complex actions with targets:
// 
// Can target specific objects, random objects, or all objects
// Handles room actions (operation type "0")
// 
// 
/* Process conditional movement */
void process_conditional_movement(void) {
    char temp[10];
    mid_str(temp, record_content, 18, 1);
    int condition_type = atoi(temp);
    
    switch (condition_type) {
        case 1:
        case 2: check_player_state(); break;
        case 3: process_successful_condition(); break;
        case 4: process_failed_condition(); break;
        case 5: process_both_conditions(); break;
    }
}

/* Check player state */
void check_player_state(void) {
    char temp[10];
    mid_str(temp, record_content, 18, 1);
    int required_state = atoi(temp);
    
    if (required_state != player_state) {
        process_failed_condition();
    } else {
        process_mandatory_items();
    }
}

/* Process mandatory items */
void process_mandatory_items(void) {
    char temp[10];
    int list_offset_local = 0;
    
    while (list_offset_local < 10) {
        /* Check required items (must be carried) */
        mid_str(temp, record_content, list_offset_local + 19, 2);
        parse_item_number(temp);
        
        if (parsed_number < 0) {
            /* Check gremlin presence */
            if (gremlin_location[-parsed_number] != current_room) {
                process_failed_condition();
                return;
            }
        } else if (parsed_number > 0) {
            /* Check artifact is carried */
            if (artifact_location[parsed_number] != 0) {
                process_failed_condition();
                return;
            }
        }
        
        /* Check forbidden items (must not be present) */
        mid_str(temp, record_content, list_offset_local + 31, 2);
        parse_item_number(temp);
        
        if (parsed_number < 0) {
            if (gremlin_location[-parsed_number] == current_room) {
                process_failed_condition();
                return;
            }
        } else if (parsed_number > 0) {
            if (artifact_location[parsed_number] == 0) {
                process_failed_condition();
                return;
            }
        }
        
        list_offset_local += 2;
    }
    
    check_additional_conditions();
}

/* Check additional conditions */
void check_additional_conditions(void) {
    char temp[10];
    char saved_record[RECORD_SIZE + 1];
    strcpy(saved_record, record_content);
    
    mid_str(temp, record_content, 43, 4);
    current_record = atoi(temp);
    if (current_record == 0) {
        process_successful_condition();
        return;
    }
    
    get_record();
    mid_str(temp, record_content, 8, 1);
    char required_state[5];
    strcpy(required_state, temp);
    strcpy(record_content, saved_record);
    
    mid_str(temp, record_content, 47, 1);
    if (strcmp(temp, required_state) != 0) {
        process_failed_condition();
        return;
    }
    
    mid_str(temp, record_content, 48, 1);
    if (atoi(temp) > (rand() % 10)) {
        process_failed_condition();
    } else {
        process_successful_condition();
    }
}

/* Process successful condition */
void process_successful_condition(void) {
    char temp[10];
    mid_str(temp, record_content, 10, 4);
    current_record = atoi(temp);
    left_str(action, record_content, 5);
    display_message();
    execute_action();
}

/* Process failed condition */
void process_failed_condition(void) {
    char temp[10];
    mid_str(temp, record_content, 14, 4);
    current_record = atoi(temp);
    mid_str(action, record_content, 5, 5);
    display_message();
    execute_action();
}

/* Process both conditions */
void process_both_conditions(void) {
    mid_str(secondary_action, record_content, 5, 5);
    process_successful_condition();
}

/* Parse item number */
void parse_item_number(char *item_string) {
    parsed_number = atoi(item_string);
    
    char last_char = item_string[strlen(item_string) - 1];
    if (last_char != 'P') return;
    
    /* Negative encoding for gremlins */
    parsed_number = 0 - 10 * parsed_number - (last_char & 0x0F);
}

/* Find action in record */
void find_action_in_record(void) {
    get_record();
    int search_index_local = 33;
    
    while (search_index_local < 90) {
        char temp[5];
        mid_str(temp, record_content, search_index_local, 1);
        if (strcmp(temp, "E") == 0) break;
        
        mid_str(temp, record_content, search_index_local, 3);
        if (strcmp(temp, cur_command) == 0) {
            mid_str(action, record_content, search_index_local + 3, 5);
            return;
        }
        
        mid_str(temp, record_content, search_index_local + 1, 2);
        char first_char[2];
        first_char[0] = cur_command[0];
        first_char[1] = '\0';
        
        if (strcmp(temp, "??") == 0 && record_content[search_index_local] == cur_command[0]) {
            right_str(command_args, cur_command, 2);
            mid_str(action, record_content, search_index_local + 3, 5);
            return;
        }
        
        search_index_local += 8;
    }
}

/* Process description */
void process_description(void) {
    char temp[10];
    mid_str(temp, record_content, 8, 1);
    int state_value = atoi(temp);
    mid_str(temp, record_content, 6 + 4 * state_value, 4);
    current_record = atoi(temp);
    display_message();
}

/* Process dynamic message */
void process_dynamic_message(void) {
    char temp[10];
    right_str(temp, action, 4);
    
    if (temp[3] == '0') {
        mid_str(temp, command_args, 0, strlen(command_args));
        current_record = gremlin_record[atoi(temp)];
    } else {
        mid_str(temp, command_args, 0, strlen(command_args));
        current_record = artifact_record[atoi(temp)];
    }
    
    get_record();
    process_artifact_description();
    strcpy(text_output, "The ");
    process_text_output();
}

/* Process artifact description */
void process_artifact_description(void) {
    char temp[10];
    mid_str(temp, record_content, 8, 1);
    int state_value = atoi(temp);
    mid_str(temp, record_content, 6 + 4 * state_value, 4);
    current_record = atoi(temp);
}

/* Handle artifact action */
void handle_artifact_action(int artifact_idx) {
    if (strcmp(word1, "CARR") == 0) {
        handle_carry_artifact(artifact_idx);
    } else if (strcmp(word1, "DROP") == 0) {
        handle_drop_artifact(artifact_idx);
    } else if (strcmp(word1, "THRO") == 0) {
        handle_throw_artifact(artifact_idx);
    } else {
        handle_use_artifact(artifact_idx);
    }
}

/* Handle specific artifact */
void handle_specific_artifact(int artifact_idx) {
    if (strcmp(word1, "CARR") == 0) {
        handle_carry_artifact(artifact_idx);
        return;
    }
    
    if (strcmp(word1, "DROP") == 0 || strcmp(word1, "THRO") == 0) {
        if (artifact_location[artifact_idx] != 0) {
            current_record = 339;
            display_message();
            return;
        }
        
        carry_count--;
        place_artifact(artifact_idx);
        
        if (strcmp(word1, "DROP") == 0) {
            return;
        } else {
            strcpy(cur_command, "4");
            handle_use_artifact(artifact_idx);
        }
        return;
    }
    
    handle_use_artifact(artifact_idx);
}

/* Handle carry artifact */
void handle_carry_artifact(int artifact_idx) {
    char temp[10];
    current_record = artifact_record[artifact_idx];
    get_record();
    
    mid_str(temp, record_content, 8, 1);
    int state_value = atoi(temp);
    mid_str(temp, record_content, 85, 4);
    new_place = atoi(temp);
    
    if (new_place != 0) {
        current_record = new_place;
        get_record();
        execute_action();
        return;
    }
    
    if (carry_count >= 6) {
        current_record = 340;
        display_message();
        return;
    }
    
    carry_count++;
    artifact_location[artifact_idx] = 0; /* 0 means carried */
    execute_carry_action();
}

/* Handle drop artifact */
void handle_drop_artifact(int artifact_idx) {
    if (artifact_location[artifact_idx] != 0) {
        current_record = 339;
        display_message();
        return;
    }
    
    carry_count--;
    if (carry_count < 0) carry_count = 0;
    place_artifact(artifact_idx);
}

/* Handle throw artifact */
void handle_throw_artifact(int artifact_idx) {
    handle_drop_artifact(artifact_idx);
    strcpy(cur_command, "4");
    handle_use_artifact(artifact_idx);
}

/* Handle use artifact */
void handle_use_artifact(int artifact_idx) {
    current_record = artifact_record[artifact_idx];
    get_record();
    
    strcpy(cur_command, "X"); /* Default no action */
    for (action_index = 66; action_index < 76; action_index += 4) {
        char temp[5];
        mid_str(temp, record_content, action_index, 4);
        if (strcmp(word1, temp) == 0) {
            sprintf(cur_command, "%d", (action_index - 62) / 4);
            break;
        }
    }
    
    if (strcmp(cur_command, "X") == 0) {
        current_record = 338;
        display_message();
        return;
    }
    
    sprintf(cur_command + strlen(cur_command), "%02d", artifact_idx / 100);
    execute_action();
}

/* Execute carry action */
void execute_carry_action(void) {
    strcpy(secondary_action, "0");
    execute_action();
}

/* Execute complex action */
void execute_complex_action(void) {
    char temp[10];
    char operation_type[5];
    mid_str(operation_type, action, 2, 1);
    int flag_type = action[1] - '0';
    
    right_str(temp, action, 2);
    if (strcmp(temp, "??") == 0) {
        /* Replace ?? with command args */
        strncpy(action + 3, command_args, 2);
    }
    
    if (operation_type[0] == '0') {
        current_record = current_room;
        process_target_action();
        return;
    }
    
    right_str(temp, action, 2);
    int target_index = atoi(temp);
    
    if (target_index > 0) {
        process_specific_target(target_index, operation_type);
        return;
    }
    
    if (flag_type == 3) {
        process_random_target(operation_type);
        return;
    }
    
    process_all_targets(operation_type);
}



// Target Processing Functions:
// process_specific_target() - Processes action on a specific artifact or gremlin by index
// process_all_targets() - Finds and processes first eligible target in room/inventory
// process_random_target() - Selects random artifact/gremlin and processes action
// check_target_eligibility() - 30% chance to select target (simulates randomness)
// process_target_action() - Routes to appropriate action based on action code (state change, move, destroy, etc.)
// State & Location Functions:
// process_state_change() - Toggles object state between 1 and 2, displays state message
// process_location_change() - Moves object to warehouse or specified location
// process_destroy() - Removes object from game (with optional message)
// destroy_object() - Actually removes artifact/gremlin from game world
// Player Action Functions:
// execute_player_action() - Routes player-specific actions (death, state change, movement, etc.)
// handle_player_death() - Handles player death, prompts for continue, drops all items
// handle_player_state_change() - Changes player state and moves to new location
// handle_player_movement() - Applies penalty and executes movement
// handle_player_command() - Executes a command as the player
// handle_player_state_toggle() - Toggles state of another object
// Complex Actions:
// process_complex_movement() - Handles multi-state changes (up to 17 objects), then executes action
// process_feed_kill_command() - Handles feeding/killing creatures with required items
// process_successful_feed_kill() - Consumes item, affects gremlin (feed resets aggression, kill removes)
// Utility Functions:
// place_artifact() - Places artifact at room or special location (checks for "***" marker)
// process_object_message() - Displays "The [object] [description]" message
// process_location_description() - Wrapper that calls display_message()
// execute_drop_action() - Drops object and continues with secondary action
// execute_state_action() - Changes object state and continues with secondary action
// execute_destroy_action() - Destroys object and continues with secondary action
/* Process specific target */
void process_specific_target(int target_idx, char *operation_type) {
    if (operation_type[0] == '1') {
        current_record = artifact_record[target_idx];
    } else {
        current_record = gremlin_record[target_idx];
    }
    process_target_action();
}

/* Process all targets */
void process_all_targets(char *operation_type) {
    found_target = 0;
    
    if (operation_type[0] == '1') {
        for (artifact_index = 1; artifact_index <= num_artifacts; artifact_index++) {
            if (artifact_location[artifact_index] == 0 || 
                artifact_location[artifact_index] == current_room) {
                check_target_eligibility(artifact_index);
                if (found_target > 0) {
                    current_record = artifact_record[found_target];
                    process_target_action();
                    return;
                }
            }
        }
    } else {
        for (gremlin_index = 1; gremlin_index <= num_gremlins; gremlin_index++) {
            if (gremlin_location[gremlin_index] == current_room) {
                check_target_eligibility(gremlin_index);
                if (found_target > 0) {
                    current_record = gremlin_record[found_target];
                    process_target_action();
                    return;
                }
            }
        }
    }
    
    current_record = 344;
    display_message();
}

/* Process random target */
void process_random_target(char *operation_type) {
    int random_index;
    
    if (operation_type[0] == '1') {
        do {
            random_index = (rand() % num_artifacts) + 1;
            if (artifact_location[random_index] == 0 || 
                artifact_location[random_index] == current_room) break;
        } while (1);
        
        current_record = artifact_record[random_index];
        get_record();
        
        char temp[5];
        mid_str(temp, record_content, 98, 1);
        if (strcmp(temp, "1") == 0) {
            current_record = 344;
            display_message();
            return;
        }
    } else {
        do {
            random_index = (rand() % num_gremlins) + 1;
            if (gremlin_location[random_index] == current_room) break;
        } while (1);
        
        current_record = gremlin_record[random_index];
    }
    
    process_target_action();
}

/* Check target eligibility */
void check_target_eligibility(int idx) {
    if (found_target == 0) {
        if ((rand() % 10) > 2) return;
    }
    found_target = idx;
}

/* Process target action */
void process_target_action(void) {
    get_record();
    
    int action_flag = action[0] - '0' - 3;
    
    switch (action_flag) {
        case 0: process_state_change(); break;
        case 1: process_location_change(); break;
        case 2: process_location_change(); break;
        case 3: process_destroy(); break;
        case 4: execute_carry_action(); break;
        case 5: execute_drop_action(); break;
        default: break;
    }
}

/* Process state change */
void process_state_change(void) {
    char temp[10];
    mid_str(temp, record_content, 8, 1);
    int current_state = atoi(temp);
    
    if (current_state == 1) {
        record_content[8] = '2';
    } else {
        record_content[8] = '1';
    }
    
    save_record();
    
    mid_str(temp, action, 2, 1);
    if (strcmp(temp, "0") == 0) {
        player_state = record_content[8] - '0';
        strcpy(place_record, record_content);
    }
    
    mid_str(temp, record_content, 8, 1);
    int new_state = atoi(temp);
    mid_str(temp, record_content, 14 + 4 * new_state, 4);
    current_record = atoi(temp);
    display_message();
}

/* Process location change */
void process_location_change(void) {
    char temp[10];
    mid_str(temp, record_content, 92, 4);
    new_place = atoi(temp);
    
    if (new_place != current_room) {
        new_place = warehouse_room;
        if (new_place == current_room) new_place = 9999;
    }
    
    mid_str(temp, action, 2, 1);
    if (strcmp(temp, "1") == 0) {
        if (artifact_location[found_target] == 0) carry_count--;
        artifact_location[found_target] = new_place;
        current_record = 346;
        process_object_message();
    } else {
        gremlin_location[found_target] = new_place;
        if (action[0] == '1') {
            current_record = 346;
            process_object_message();
        } else {
            current_record = 347;
            process_object_message();
        }
    }
}

/* Process destroy */
void process_destroy(void) {
    if (action[0] == '9') {
        destroy_object();
        return;
    }
    
    strcpy(text_output, "A ");
    process_text_output();
    process_artifact_description();
    process_description();
    current_record = 348;
    display_message();
    destroy_object();
}

/* Destroy object */
void destroy_object(void) {
    char temp[5];
    mid_str(temp, action, 2, 1);
    
    if (strcmp(temp, "1") == 0) {
        if (artifact_location[found_target] == 0) carry_count--;
        place_artifact(found_target);
    } else {
        gremlin_location[found_target] = -1;
    }
}

/* Execute player action */
void execute_player_action(void) {
    char l_first = action[0];
    
    if (l_first == '4') {
        handle_player_death();
    } else if (l_first == '5') {
        handle_player_state_change();
    } else if (l_first == '6') {
        handle_player_movement();
    } else if (l_first == '7') {
        handle_player_command();
    } else if (l_first == '8') {
        handle_player_state_toggle();
    }
}

/* Handle player death */
void handle_player_death(void) {
    char death_message[10];
    right_str(death_message, action, 4);
    current_record = atoi(death_message);
    display_message();
    
    current_record = 345;
    display_message();
    flush_output();
    
    printf(":");
    fgets(user_response, sizeof(user_response), stdin);
    
    user_response[0] = toupper(user_response[0]);
    if (user_response[0] == 'N') {
        handle_end_command();
        return;
    }
    
    move_count += 10;
    
    for (artifact_index = 1; artifact_index <= num_artifacts; artifact_index++) {
        if (artifact_location[artifact_index] == 0) {
            place_artifact(artifact_index);
        }
    }
    
    carry_count = 0;
    current_room = home_room;
    action_result = 'Y';
}

/* Handle player state change */
void handle_player_state_change(void) {
    player_state = 1;
    place_record[8] = '1';
    strcpy(record_content, place_record);
    current_record = current_room;
    save_record();
    execute_move_action();
}

/* Handle player movement */
void handle_player_movement(void) {
    char score_change[10];
    right_str(score_change, action, 4);
    parse_item_number(score_change);
    penalty_points += parsed_number;
    
    strcpy(action, secondary_action);
    strcpy(secondary_action, "0");
    execute_action();
}

/* Handle player command */
void handle_player_command(void) {
    mid_str(cur_command, action, 1, 3);
    process_command();
}

/* Handle player state toggle */
void handle_player_state_toggle(void) {
    char temp[10];
    right_str(temp, action, 4);
    current_record = atoi(temp);
    get_record();
    
    mid_str(temp, record_content, 8, 1);
    int current_state = atoi(temp);
    
    if (current_state == 1) {
        record_content[8] = '2';
    } else {
        record_content[8] = '1';
    }
    
    save_record();
    
    strcpy(action, secondary_action);
    strcpy(secondary_action, "0");
    if (strcmp(action, "0") != 0) execute_action();
}

/* Process complex movement */
void process_complex_movement(void) {
    char saved_record[RECORD_SIZE + 1];
    char temp[10];
    strcpy(saved_record, record_content);
    
    for (process_index = 0; process_index < 86; process_index += 5) {
        mid_str(temp, saved_record, process_index, 4);
        current_record = atoi(temp);
        if (current_record == 0) break;
        
        get_record();
        record_content[8] = saved_record[process_index + 4];
        save_record();
    }
    
    mid_str(action, saved_record, 90, 5);
    execute_action();
}

/* Process feed/kill command */
void process_feed_kill_command(void) {
    char required_items[20];
    char temp[10];
    int message_number;
    
    if (word1[0] == 'F') {
        mid_str(required_items, gremlin_data, 66, 8);
        message_number = 354;
    } else {
        strcpy(required_items, "00");
        mid_str(temp, gremlin_data, 74, 6);
        strcat(required_items, temp);
        message_number = 351;
    }
    
    int item_index_local = 0;
    int found_item = 0;
    
    while (item_index_local < 7) {
        mid_str(temp, required_items, item_index_local, 2);
        int required_item = atoi(temp);
        
        if (required_item == 0) break;
        
        if (artifact_location[required_item] == 0) {
            process_successful_feed_kill(required_item, message_number);
            found_item = 1;
            break;
        }
        
        item_index_local += 2;
    }
    
    if (found_item == 0) {
        process_description();
        strcpy(text_output, word2);
        process_text_output();
        
        if (word1[0] == 'F') {
            current_record = 341;
            display_message();
        }
    }
}

/* Process successful feed/kill */
void process_successful_feed_kill(int item_idx, int message_number) {
    char temp[10];
    sprintf(text_output, "The %s", word2);
    process_text_output();
    
    current_record = message_number + 1;
    display_message();
    
    current_record = artifact_record[item_idx];
    get_record();
    process_description();
    
    if (word1[0] == 'F') {
        artifact_location[item_idx] = -1;
        mid_str(temp, gremlin_data, 85, 1);
        gremlin_factor[target_gremlin] = atoi(temp);
    } else {
        gremlin_location[target_gremlin] = -1;
    }
}

/* Place artifact */
void place_artifact(int artifact_idx) {
    char temp[10];
    mid_str(temp, place_record, 89, 3);
    
    if (strcmp(temp, "***") == 0) {
        mid_str(temp, place_record, 93, 4);
        artifact_location[artifact_idx] = atoi(temp);
    } else {
        artifact_location[artifact_idx] = current_room;
    }
}

/* Process object message */
void process_object_message(void) {
    if (action[0] == '9') return;
    
    int saved_record = current_record;
    
    strcpy(text_output, "The ");
    process_text_output();
    process_artifact_description();
    process_description();
    
    current_record = saved_record;
    display_message();
}

/* Process location description */
void process_location_description(void) {
    display_message();
}

/* Execute drop action */
void execute_drop_action(void) {
    char temp[5];
    mid_str(temp, action, 2, 1);
    
    if (strcmp(temp, "1") == 0) {
        if (artifact_location[found_target] == 0) {
            carry_count--;
        }
        place_artifact(found_target);
        current_record = 346;
        display_message();
    }
    
    strcpy(action, secondary_action);
    strcpy(secondary_action, "0");
    if (strcmp(action, "0") != 0) execute_action();
}

/* Execute state action */
void execute_state_action(void) {
    char temp[10];
    right_str(temp, action, 4);
    current_record = atoi(temp);
    get_record();
    
    mid_str(temp, record_content, 8, 1);
    int current_state = atoi(temp);
    
    if (current_state == 1) {
        record_content[8] = '2';
    } else {
        record_content[8] = '1';
    }
    
    save_record();
    
    mid_str(temp, record_content, 8, 1);
    int new_state = atoi(temp);
    mid_str(temp, record_content, 14 + 4 * new_state, 4);
    current_record = atoi(temp);
    display_message();
    
    strcpy(action, secondary_action);
    strcpy(secondary_action, "0");
    if (strcmp(action, "0") != 0) execute_action();
}

/* Execute destroy action */
void execute_destroy_action(void) {
    if (action[0] == '9') {
        destroy_object();
    } else {
        strcpy(text_output, "A ");
        process_text_output();
        process_artifact_description();
        process_description();
        current_record = 348;
        display_message();
        destroy_object();
    }
    
    strcpy(action, secondary_action);
    strcpy(secondary_action, "0");
    if (strcmp(action, "0") != 0) execute_action();
}

// ' ----------------------------------------------------------------
// ' MOVEMENT AND LOCATION PROCESSING
// get_player_input()
// Gets command input from the player:
// 
// Flushes output buffer and displays current score
// Reads user input from stdin
// Removes trailing newline character
// Updates move count
// Calls parse_command to process the input
// ' ----------------------------------------------------------------
void process_movement() {
    char temp_string[256];
    char follow_string[256];

    action_result = 'Y';
    strcpy(temp_string, "The");
    strcpy(follow_string, "X");

    for (gremlin_index=1; gremlin_index< num_gremlins; gremlin_index++) {
        if (gremlin_location[gremlin_index] == current_room) {
            current_record = gremlin_record[gremlin_index];
            get_record();

            int state_value = *(record_content+9) - '0';
            if (*(record_content+80+2*state_value)-'0' > rand() * 9) {
                // Gremlin follows
                strcpy(text_output, temp_string);
                process_text_output();

                if (strcmp(temp_string, "The") == 0) {
                    strcpy(follow_string, "%4has");
                } else {
                    strcpy(follow_string, "%4have");
                }

                strcpy(temp_string, "%4and");
                process_description();

                gremlin_location[gremlin_index] = -new_place;
            }
        }
    }

    current_room = new_place;

    if (strcmp(follow_string, "X")) {
        strcpy(text_output, follow_string);
        strcat(text_output, " following you. ");
        process_text_output();
        action_result = 'N';
    }
}

// ' ----------------------------------------------------------------
// ' COMMAND PROCESSING
// process_movement()
// Handles the actual movement of the player to a new location:
// 
// Checks each gremlin in the current room to see if it follows
// Uses random chance based on gremlin's state to determine following
// Sets gremlin location to negative (following state)
// Updates current room to new location
// Displays which creatures are following
// ' ----------------------------------------------------------------
void get_player_input() {
    flush_output();
    calculate_score();

    printf("%d: ", score);
    fgets(user_input, sizeof(user_input), stdin); // Catch EOF
    random_seed = strlen(user_input);
    move_count++;
    parse_command(user_input);
}

// ' ----------------------------------------------------------------
// ' DEBUG AND UTILITY COMMANDS
// handle_debug_command()
// Provides debugging/cheat commands (triggered by "ZPQR"):
// 
// ZPQR ARTI - Gives all artifacts to player
// ZPQR GREM - Removes all gremlins from game
// ZPQR nnnn - Teleports to room number nnnn

// ' ----------------------------------------------------------------
void handle_debug_command() {
    if (strcmp(word2, "ARTI") == 0) {
        for (artifact_index=1; artifact_index<num_artifacts; artifact_index++)
            artifact_location[artifact_index] = 0;
        carry_count = num_artifacts;
    } else if (strcmp(word2, "GREM") == 0) {
        for(gremlin_index=1; gremlin_index<num_gremlins; gremlin_index++)
            gremlin_location[gremlin_index] = -1;
    } else {
        current_room = atoi(word2);
        action_result = 'Y';
    }
}







/* Start game loop */
void start_game_loop(void) {
    action_result = 'N';
    while (1) {
        if (action_result == 'Y') {
            process_movement();
        } else {
            process_gremlins();
        }
        
        arrive_at_location();
        
        if (action_result != 'Y') {
            check_gremlin_attacks();
        }
        
        process_location_description();
        get_player_input();
        process_command();
    }
}

/* Main function */
int main(void) {
    srand(time(NULL));
    
    initialize_game();
    load_game_data();
    validate_game_state();
    action_result = 'Y';
    arrive_at_location();
    start_game_loop();
    
    fclose(game_file);
    return 0;
}
