#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <dirent.h>
#include <sys/stat.h>
#include <stdbool.h>

#define COLOR_GREEN "\033[1;32m"
#define COLOR_RESET "\033[0m"
#define MAX_FILES 100
#define MAX_PATH_LEN 1024

void print_green(const char *message) {
    printf("%s%s%s", COLOR_GREEN, message, COLOR_RESET);
}

void print_menu() {
    //clear_screen();
    print_green("");
    
    printf("[Information]\n");
    printf("   If you found any bug, pls dm me in telegram:\n");
    printf("   t.me/khayloaf\n\n");
    
    printf("[Available Menu]\n");
    printf("   1. Flash Fastboot ROM\n");
    printf("   2. Sideload ROM, Modules, etc\n");
    printf("   3. Unlock Bootloader (Coming soon)\n");
}

int is_directory(const char *path) {
    struct stat statbuf;
    if (stat(path, &statbuf) != 0)
        return 0;
    return S_ISDIR(statbuf.st_mode);
}

int find_files(const char *path, const char *ext, char files[][MAX_PATH_LEN]) {
    DIR *dir;
    struct dirent *ent;
    int count = 0;
    
    if ((dir = opendir(path)) != NULL) {
        while ((ent = readdir(dir)) != NULL && count < MAX_FILES) {
            if (ent->d_type == DT_REG) {
                const char *name = ent->d_name;
                const char *dot = strrchr(name, '.');
                if (dot && !strcmp(dot, ext)) {
                    strncpy(files[count], name, MAX_PATH_LEN);
                    count++;
                }
            }
        }
        closedir(dir);
    }
    return count;
}

void wait_for_fastboot() {
    char dots[4] = "";
    while (true) {
        FILE *fp = popen("fastboot devices 2>/dev/null", "r");
        if (fp) {
            char output[256];
            bool found = false;
            while (fgets(output, sizeof(output), fp)) {
                if (strstr(output, "fastboot")) {
                    printf("\r   ✅ Device detected in fastboot mode!\033[K");
                    fflush(stdout);
                    sleep(1);
                    printf("\r\033[K");
                    pclose(fp);
                    return;
                }
            }
            pclose(fp);
        }

        // Update dots animation
        if (strcmp(dots, "") == 0) strcpy(dots, ".");
        else if (strcmp(dots, ".") == 0) strcpy(dots, "..");
        else if (strcmp(dots, "..") == 0) strcpy(dots, "...");
        else strcpy(dots, "");
        
        printf("\r   Waiting for device in fastboot mode%s\033[K", dots);
        fflush(stdout);
        usleep(500000);
    }
}

void wait_for_sideload() {
    char dots[4] = "";
    while (true) {
        FILE *fp = popen("adb devices 2>/dev/null", "r");
        if (fp) {
            char output[256];
            bool found = false;
            while (fgets(output, sizeof(output), fp)) {
                if (strstr(output, "sideload")) {
                    printf("\r   ✅ Device detected in sideload mode!\033[K");
                    fflush(stdout);
                    sleep(1);
                    printf("\r\033[K");
                    pclose(fp);
                    return;
                }
            }
            pclose(fp);
        }

        // Update dots animation
        if (strcmp(dots, "") == 0) strcpy(dots, ".");
        else if (strcmp(dots, ".") == 0) strcpy(dots, "..");
        else if (strcmp(dots, "..") == 0) strcpy(dots, "...");
        else strcpy(dots, "");
        
        printf("\r   Waiting for device in sideload mode%s\033[K", dots);
        fflush(stdout);
        usleep(500000);
    }
}

void flash_fastboot_rom() {
    printf("[GUIDE]\n");
    printf("   Type the command to go to your ROM folder\n");
    printf("   (example: cd /sdcard/ROM/)\n");
    printf("-> ");
    
    char cmd[MAX_PATH_LEN];
    fgets(cmd, sizeof(cmd), stdin);
    cmd[strcspn(cmd, "\n")] = 0; // Remove newline
    
    char *path = strstr(cmd, "cd ");
    if (!path) {
        printf("❌ Invalid command. Must start with 'cd '\n");
        sleep(2);
        return;
    }
    path += 3; // Skip "cd "
    
    if (!is_directory(path)) {
        printf("❌ Folder not found!\n");
        sleep(2);
        return;
    }
    
    if (chdir(path) != 0) {
        printf("❌ Failed to change directory\n");
        sleep(2);
        return;
    }
    
    if (!is_directory("images")) {
        printf("❌ 'images' folder not found!\n");
        sleep(2);
        return;
    }
    
    char img_files[MAX_FILES][MAX_PATH_LEN];
    int img_count = find_files("images", ".img", img_files);
    int bin_count = find_files("images", ".bin", img_files + img_count);
    
    if (img_count + bin_count == 0) {
        printf("❌ No .img or .bin files in 'images' folder!\n");
        sleep(2);
        return;
    }
    
    char script_files[MAX_FILES][MAX_PATH_LEN];
    int script_count = find_files(".", ".sh", script_files);
    if (script_count == 0) {
        printf("❌ No flashable .sh files found!\n");
        sleep(2);
        return;
    }
    
    printf("\n[SELECTION]\n");
    printf("   Available flashable scripts:\n");
    
    for (int i = 0; i < script_count; i++) {
        char *dot = strrchr(script_files[i], '.');
        if (dot) *dot = '\0';
        printf("   %d) %s\n", i+1, script_files[i]);
    }
    
    printf("-> Select a script by number (1-%d): ", script_count);
    int choice;
    scanf("%d", &choice);
    getchar(); // Consume newline
    
    if (choice < 1 || choice > script_count) {
        printf("❌ Invalid selection. Must be between 1 and %d\n", script_count);
        sleep(2);
        return;
    }
    
    printf("-> You selected: %s\n\n", script_files[choice-1]);
    printf("[STARTED]\n");
    
    wait_for_fastboot();
    
    printf("   ⚡ Starting flashing process...\n\n");
    char command[MAX_PATH_LEN + 10];
    snprintf(command, sizeof(command), "bash %s", script_files[choice-1]);
    system(command);
    sleep(2);
}

void sideload_rom() {
    printf("[GUIDE]\n");
    printf("   Type the command to go to your files folder\n");
    printf("   (example: cd /sdcard/FILES/)\n");
    printf("-> ");
    
    char cmd[MAX_PATH_LEN];
    fgets(cmd, sizeof(cmd), stdin);
    cmd[strcspn(cmd, "\n")] = 0;
    
    char *path = strstr(cmd, "cd ");
    if (!path) {
        printf("❌ Invalid command. Must start with 'cd '\n");
        sleep(2);
        return;
    }
    path += 3;
    
    if (!is_directory(path)) {
        printf("❌ Folder not found!\n");
        sleep(2);
        return;
    }
    
    char zip_files[MAX_FILES][MAX_PATH_LEN];
    int zip_count = find_files(path, ".zip", zip_files);
    if (zip_count == 0) {
        printf("❌ No .zip files found in %s\n", path);
        sleep(2);
        return;
    }
    
    printf("\n[SELECTION]\n");
    printf("   Available flashable files:\n");
    
    // Array to store valid flashable zips
    char valid_zips[MAX_FILES][MAX_PATH_LEN];
    int valid_count = 0;
    
    for (int i = 0; i < zip_count; i++) {
        char full_path[MAX_PATH_LEN];
        snprintf(full_path, sizeof(full_path), "%s/%s", path, zip_files[i]);
        
        // Check if zip contains META-INF folder
        char command[MAX_PATH_LEN + 50];
        snprintf(command, sizeof(command), 
                "unzip -l \"%s\" | grep -q \"META-INF/\"", full_path);
        
        int result = system(command);
        if (result == 0) {
            char *dot = strrchr(zip_files[i], '.');
            if (dot) *dot = '\0';
            printf("   %d) %s\n", valid_count+1, zip_files[i]);
            strncpy(valid_zips[valid_count], zip_files[i], MAX_PATH_LEN);
            valid_count++;
        }
    }
    
    if (valid_count == 0) {
        printf("❌ No flashable files found (missing META-INF folder).\n");
        sleep(2);
        return;
    }
    
    printf("-> Choose a file to flash (1-%d): ", valid_count);
    int choice;
    scanf("%d", &choice);
    getchar();
    
    if (choice < 1 || choice > valid_count) {
        printf("❌ Invalid selection. Must be between 1 and %d\n", valid_count);
        sleep(2);
        return;
    }
    
    printf("-> Selected file: %s.zip\n\n", valid_zips[choice-1]);
    printf("[STARTED]\n");
    
    wait_for_sideload();
    
    printf("   ⚡ Starting flashing process...\n\n");
    char command[MAX_PATH_LEN + 20];
    snprintf(command, sizeof(command), "adb sideload \"%s/%s.zip\"", path, valid_zips[choice-1]);
    system(command);
    sleep(2);
}

int main() {
    while (true) {
        print_menu();
        
        printf("-> Choose an option: ");
        int option;
        scanf("%d", &option);
        getchar(); // Consume newline
        
        switch (option) {
            case 1:
                flash_fastboot_rom();
                break;
            case 2:
                sideload_rom();
                break;
            case 3:
                printf("Coming soon!\n");
                sleep(2);
                break;
            default:
                return 0;
        }
    }
    
    return 0;
}
