#!/bin/bash

# get grid size from user
grid_size=1

while [ -z $grid_size ] || [ $grid_size -lt 3 ] || [ $grid_size -gt 8 ]; do
    echo -n "ENTER GRID SIZE [3-8]: "
    read grid_size

    if [ $grid_size -lt 3 ]; then
    	echo "Size must be greater than 2!"
    elif [ $grid_size -gt 8 ]; then
        echo "Size must be lesser than 9!"
    fi
done

# set up starting values
declare -a final_score
final_score[1]=0 # score of player 1
final_score[2]=0 # score of player 2

is_exit_requested=false
is_set_finished=false
active_player=1 # player who gets the turn

declare -a grid_flags
for (( i=0; i<$grid_size; i++ )) do
    for (( j=0; j<$grid_size; j++ )) do
        grid_flags[$i,$j]=0
    done
done

# set up helper functions
function printBoard {
    for (( i=0; i<$grid_size; i++ )) do
        for (( j=0; j<$grid_size; j++ )) do
            echo -n "${grid_flags[$i,$j]} "
        done
    echo
    done
}

function selectIndex {
    echo -n "ENTER GRID INDEX: "
    read selected_index
    if [[ $selected_index =~ ^-?[0-9]+$ ]]; then # check if integer
        local max_value=$(($grid_size * $grid_size - 1))
	if [ $selected_index -gt $max_value ]; then
            echo "MAXIMUM INDEX IS "$max_value
            selectIndex
        fi
    else 
        echo -e "YOU MUST PROVIDE A NUMBER! \n"
        selectIndex
    fi
}

function askToContinue {
    echo -n "DO YOU WANT TO PLAY ANOTHER SET? [Y/n] "
    read continue_playing
    continue_playing=$(echo $continue_playing | tr '[:upper:]' '[:lower:]')
    case "$continue_playing" in
        "y") is_exit_requested=false ;;
        "n") is_exit_requested=true ;;
        *) echo -e "\nINVALID ANSWER. PRINT 'Y/y' or 'N/n'"; askToContinue
    esac
}

# start game loop
while ! $is_exit_requested; do

    while ! $is_set_finished; do
        printBoard
        
        echo -e "\nTURN OF PLAYER $active_player"
        selectIndex
        
        tmp_val=$((selected_index/grid_size))
        row=${tmp_val%.*}
        col=$((selected_index%grid_size))

        (( active_player = active_player==1 ? 2 : 1 ))
    done

    askToContinue
done

