#!/bin/bash

clear

# get grid size from user
#grid_size=3
while [[ -z $grid_size || !$grid_size =~ ^-?[0-9]+$ || $grid_size -lt 3 || $grid_size -gt 8 ]]; do
    echo -n "ENTER GRID SIZE [3-8]: "
    read grid_size

    if [[ $grid_size =~ ^-?[0-9]+$ ]]; then # check if integer
        if [ $grid_size -lt 3 ]; then
            echo -e "Size must be greater than 2!\n"
        elif [ $grid_size -gt 8 ]; then
            echo -e "Size must be lesser than 9!\n"
        fi
    else
        echo -e "Enter valid number!\n"
    fi
done

# set up starting values
last_index=$(($grid_size * $grid_size - 1))

final_score=()
final_score[1]=0 # score of player 1
final_score[2]=0 # score of player 2

is_exit_requested=false
is_set_finished=false
active_player=1 # player who gets the turn

grid_flags=()

# set up helper functions
function initGrid {
    for (( i=0; i<$((grid_size*grid_size)); i++ )) do
        grid_flags[$i]=0
    done
}

function printBoard {
    for (( r=0; r<$grid_size; r++ )) do
        for (( c=0; c<$grid_size; c++ )) do
	        local index=$((r * grid_size + c))
            local flag=${grid_flags[$index]}
            local char="?"

            if [ $flag -eq 1 ]; then
                char=" X "
                if [ $last_index -ge 10 ]; then char=" "$char; fi
            elif [ $flag -eq 2 ]; then
                char=" O "
                if [ $last_index -ge 10 ]; then char=" "$char; fi
            else
                if [ $last_index -lt 10 ]; then
                    char="[$index]"
                else
                    char=$( printf "[%02d]" $index )
                fi
            fi

            echo -n "  $char"
            if [ $c -lt $(( grid_size - 1 )) ]; then echo -n "  |"; fi
        done

        if [ $r -lt $(( grid_size - 1 )) ]; then
            echo
            for (( s=0; s<$grid_size; s++ )) do
                if [ $last_index -lt 10 ]; then echo -n "--------"; else echo -n "---------"; fi
            done
            echo
        fi
    done

    echo
}

function selectIndex {
    echo -n "CHOOSE GRID INDEX: "
    read selected_index
    if [[ $selected_index =~ ^-?[0-9]+$ ]]; then # check if integer
	    if [ $selected_index -gt $last_index ]; then
            echo -e "MAXIMUM INDEX IS "$last_index"!\n"
            selectIndex
        elif [ ${grid_flags[$selected_index]} -ne 0 ]; then
            echo -e "SLOT IS ALREADY TAKEN \n"
            selectIndex
        fi
    else
        echo -e "YOU MUST PROVIDE A NUMBER! \n"
        selectIndex
    fi
}

function askToContinue {
    echo -ne "\nDO YOU WANT TO PLAY ANOTHER SET? [Y/n] "
    read continue_playing
    continue_playing=$(echo $continue_playing | tr '[:upper:]' '[:lower:]')
    case "$continue_playing" in
        "y") is_set_finished=false ;;
        "n") is_exit_requested=true ;;
        *) echo "Invalid answer. Please type 'Y/y' or 'N/n'"; askToContinue
    esac
}

function validateVictory {
	local flag_count=0
    result=-1
	for (( i=0; i<$((grid_size*grid_size)); i++ )) do
	    if [ ${grid_flags[$i]} -ne 0 ]; then
            (( flag_count=flag_count+1 ))
	    fi
    done

    if [[ $flag_count -ge $(( grid_size * 2 - 1 )) ]]; then
        local seq_length=0

        for (( r=0; r<$grid_size; r++ )) do
            local break_loop=false

            for (( c=0; c<$grid_size; c++ )) do
                local current_index=$(( r * grid_size + c ))
                local current_flag=${grid_flags[$current_index]}
                local step=0

                if [[ $current_flag -eq 0 ]]; then continue; fi

                # check for horisontal victories
                if [[ $c -eq 0 || ${grid_flags[$(( current_index - 1 ))]} -ne current_flag  ]]; then
                    while [[ $(( c+step )) -lt $(( (r+1)*grid_size ))  ]]; do
                        local index_on_step=$(( r * grid_size + c + step ))
                        local flag_on_step=${grid_flags[$index_on_step]}

                        if [[ $flag_on_step -eq current_flag ]]; then
                            (( seq_length+=1 ))
                            (( step+=1 ))
                        else break; fi
                    done
                fi

                if [[ $seq_length -ge $grid_size ]]; then
                    result=$current_flag
                    break_loop=true
                    break
                else seq_length=0; step=0; fi

                # check for vertical victories
                if [[ $r -eq 0 || ${grid_flags[$(( current_index - grid_size ))]} -ne current_flag  ]]; then
                    while [[ $(( r+step )) -lt $grid_size  ]]; do
                        local index_on_step=$(( (r + step) * grid_size + c ))
                        local flag_on_step=${grid_flags[$index_on_step]}

                        if [[ $flag_on_step -eq current_flag ]]; then
                            (( seq_length+=1 ))
                            (( step+=1 ))
                        else break; fi
                    done
                fi

                if [[ $seq_length -ge $grid_size ]]; then
                    result=$current_flag
                    break_loop=true
                    break
                else seq_length=0; step=0; fi

                # check for diagonal victories
                if [[ ( $r -eq 0 || $c -eq 0 ) || ${grid_flags[$(( current_index - grid_size - 1 ))]} -ne current_flag  ]]; then
                    while [[ $(( r+step )) -lt $grid_size && $(( c+step )) -lt $(( (r+1)*grid_size )) ]]; do
                        local index_on_step=$(( (r + step) * grid_size + c + step ))
                        local flag_on_step=${grid_flags[$index_on_step]}

                        if [[ $flag_on_step -eq current_flag ]]; then
                            (( seq_length+=1 ))
                            (( step+=1 ))
                        else break; fi
                    done
                fi

                if [[ $seq_length -ge $grid_size ]]; then
                    result=$current_flag
                    break_loop=true
                    break
                else seq_length=0; step=0; fi

                # check for counter-diagonal victories
                if [[ ( $r -eq 0 || $c -eq $(( grid_size-1 )) ) || ${grid_flags[$(( current_index - grid_size + 1 ))]} -ne current_flag  ]]; then
                    while [[ $(( r+step )) -lt $grid_size && $(( c-step )) -ge 0 ]]; do
                        local index_on_step=$(( (r + step) * grid_size + c - step ))
                        local flag_on_step=${grid_flags[$index_on_step]}

                        if [[ $flag_on_step -eq current_flag ]]; then
                            (( seq_length+=1 ))
                            (( step+=1 ))
                        else break; fi
                    done
                fi

                if [[ $seq_length -ge $grid_size ]]; then
                    result=$current_flag
                    break_loop=true
                    break
                else seq_length=0; step=0; fi
            done

            if $break_loop; then break; fi
        done

        # check for a draw if winner wasn't chosen
        if [[ $result -eq -1 && $flag_count -eq $(( last_index+1 )) ]]; then
            result=0
        fi
    fi

    eval "$1=$result"
}

# start game loop
while ! $is_exit_requested; do
    clear
    initGrid

    while ! $is_set_finished; do
        clear

        echo -e "\nTURN OF PLAYER $active_player:\n"
        printBoard

        echo
        selectIndex

        grid_flags[$selected_index]=$active_player

        result=-1
        validateVictory result

        if [[ $result -ge 0 ]]; then
            is_set_finished=true
        else
            (( active_player = active_player==1 ? 2 : 1 ))
        fi
    done

    clear

    if [[ $result -eq 0 ]]; then
        printf "\nIT'S A DRAW! FINAL SCORE IS %s : %s\n\n" ${final_score[1]} ${final_score[2]}
    else
        (( final_score[result]=final_score[result]+1 ))
        printf "\nPLAYER $result HAVE WON! FINAL SCORE IS %s : %s\n\n" ${final_score[1]} ${final_score[2]}
    fi

    printBoard

    askToContinue
done

clear
