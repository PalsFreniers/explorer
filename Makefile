##========== SOURCES ==========##

SRC = src/termbox/termbox.c3
INCLUDE = 
MAIN = src/main.c3

##========== NAMES ==========##

NAME = explorer 
SRCS_DIR = ./
OBJS_DIR = ./OBJ/

##========== OBJECTS ==========##

OBJS := $(addprefix $(OBJS_DIR),$(SRC:.c=.o))
MAIN_OBJ = $(addprefix $(OBJS_DIR),$(MAIN:.c=.o))

##========== COLORS ==========##

BASE_COLOR 	=		\033[0;39m
GRAY 		=		\033[0;90m
RED 		=		\033[0;91m
GREEN 		=		\033[0;92m
YELLOW 		=		\033[0;93m
BLUE 		=		\033[0;94m
MAGENTA		=		\033[0;95m
CYAN 		=		\033[0;96m
WHITE		=		\033[0;97m

##========== COMPILATOR ==========##

C3 = c3c

##========== FLAGS ==========##

C3FLAGS = 
LDFLAGS = $(LIBS) 
LIBS = -l ./src/termbox/termbox.a

##========== MODES ==========##

ifdef DEBUG
	CFLAGS += -g -fsanitize=thread #(address, memory, thread)
	DEBUG_MODE = 1
endif

all : $(CLEAR) $(NAME)

$(NAME) : $(SRC) $(MAIN) $(INCLUDE)
	@$(C3) compile -o $(NAME) $(C3FLAGS) $(MAIN) $(SRC) $(INCLUDE) $(LDFLAGS)
	@echo "$(GREEN)-= $(NAME) compiled =-$(BASE_COLOR)"

test : $(SRC) $(MAIN) $(INCLUDE)
	@$(C3) compile-test -o $(NAME) $(C3FLAGS) $(MAIN) $(SRC) $(INCLUDE) $(LDFLAGS)
	@echo "$(GREEN)-= $(NAME) compiled =-$(BASE_COLOR)"

bench : $(SRC) $(MAIN) $(INCLUDE)
	@$(C3) compile-benchmark -o $(NAME) $(C3FLAGS) $(MAIN) $(SRC) $(INCLUDE) $(LDFLAGS)
	@echo "$(GREEN)-= $(NAME) compiled =-$(BASE_COLOR)"

clean :
	@rm -rf $(OBJS_DIR)

fclean : clean
	@rm -rf $(NAME)
	@echo "$(CYAN)Files cleaned$(BASE_COLOR)"

re : fclean all

.PHONY : all test bench bonus clean fclean re
